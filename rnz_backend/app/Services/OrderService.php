<?php

namespace App\Services;

use App\Models\OrderModel;
use App\Models\OrderItemModel;
use App\Models\VariantModel;
use App\Models\ProductModel;
use App\Models\StockMovementModel;
use App\Models\OrderStatusLogModel;
use Config\Database;
use Exception;

class OrderService
{
    protected $db;
    protected $orderModel;
    protected $orderItemModel;
    protected $variantModel;
    protected $productModel;
    protected $stockMovementModel;
    protected $orderStatusLogModel;

    public function __construct()
    {
        $this->db                  = Database::connect();
        $this->orderModel          = new OrderModel();
        $this->orderItemModel      = new OrderItemModel();
        $this->variantModel        = new VariantModel();
        $this->productModel        = new ProductModel();
        $this->stockMovementModel  = new StockMovementModel();
        $this->orderStatusLogModel = new OrderStatusLogModel();
    }

    /**
     * Generate unique order number: RNZ-YYMMDD-NNNN
     */
    public function generateOrderNumber(): string
    {
        $prefix = 'RNZ-' . date('ymd') . '-';
        $todayCount = $this->orderModel
            ->like('order_no', $prefix, 'after')
            ->countAllResults();

        $sequence = str_pad((string)($todayCount + 1), 4, '0', STR_PAD_LEFT);
        return $prefix . $sequence;
    }

    /**
     * Atomic checkout with row-locking
     */
    public function createOrder(
        int $userId,
        array $items,
        array $addressData,
        array $paymentMethodData,
        int $shippingCost = 0
    ): array {
        if (empty($items)) {
            throw new Exception('Item pesanan tidak boleh kosong.');
        }

        $this->db->transBegin();

        try {
            $subtotal = 0;
            $preparedItems = [];

            foreach ($items as $item) {
                $variantId = (int)$item['variant_id'];
                $qty       = (int)$item['qty'];

                if ($qty <= 0) {
                    throw new Exception('Jumlah item harus lebih dari nol.');
                }

                // Row-lock variant for update
                $variant = $this->db->table('product_variants')
                    ->where('id', $variantId)
                    ->get(1, 0, false) // bypass cache
                    ->getRowArray();

                // To ensure row lock in MySQL
                $lockedVariant = $this->db->query("SELECT * FROM product_variants WHERE id = ? FOR UPDATE", [$variantId])->getRowArray();

                if (!$lockedVariant) {
                    throw new Exception("Varian produk dengan ID {$variantId} tidak ditemukan.");
                }

                if ($lockedVariant['stock'] < $qty) {
                    throw new Exception("Stok tidak mencukupi untuk varian {$lockedVariant['color']}. Tersisa {$lockedVariant['stock']}.");
                }

                $product = $this->productModel->find($lockedVariant['product_id']);
                if (!$product) {
                    throw new Exception("Produk tidak ditemukan.");
                }

                $unitPrice = (int)$product['price'];
                $lineTotal = $unitPrice * $qty;
                $subtotal += $lineTotal;

                $stockBefore = (int)$lockedVariant['stock'];
                $stockAfter  = $stockBefore - $qty;

                // Deduct stock
                $this->variantModel->update($variantId, ['stock' => $stockAfter]);

                $preparedItems[] = [
                    'variant_id'    => $variantId,
                    'product_name'  => $product['name'],
                    'variant_label' => $lockedVariant['color'] . ($lockedVariant['size'] ? ' - ' . $lockedVariant['size'] : ''),
                    'unit_price'    => $unitPrice,
                    'qty'           => $qty,
                    'line_total'    => $lineTotal,
                    'stock_before'  => $stockBefore,
                    'stock_after'   => $stockAfter,
                ];
            }

            $orderNo = $this->generateOrderNumber();
            $now = date('Y-m-d H:i:s');
            $payBefore = date('Y-m-d H:i:s', strtotime('+24 hours'));
            $total = $subtotal + $shippingCost;

            $orderId = $this->orderModel->insert([
                'order_no'                => $orderNo,
                'user_id'                 => $userId,
                'status'                  => 'waiting_payment',
                'subtotal'                => $subtotal,
                'shipping_cost'           => $shippingCost,
                'total'                   => $total,
                'address_snapshot'        => json_encode($addressData),
                'payment_method_snapshot' => json_encode($paymentMethodData),
                'pay_before'              => $payBefore,
                'created_at'              => $now,
                'updated_at'              => $now,
            ]);

            foreach ($preparedItems as $pItem) {
                $this->orderItemModel->insert([
                    'order_id'      => $orderId,
                    'variant_id'    => $pItem['variant_id'],
                    'product_name'  => $pItem['product_name'],
                    'variant_label' => $pItem['variant_label'],
                    'unit_price'    => $pItem['unit_price'],
                    'qty'           => $pItem['qty'],
                    'line_total'    => $pItem['line_total'],
                ]);

                // Record stock movement
                $this->stockMovementModel->insert([
                    'variant_id'   => $pItem['variant_id'],
                    'type'         => 'order',
                    'qty_change'   => -$pItem['qty'],
                    'stock_before' => $pItem['stock_before'],
                    'stock_after'  => $pItem['stock_after'],
                    'reason'       => "Pesanan baru {$orderNo}",
                    'ref_order_id' => $orderId,
                    'admin_id'     => null,
                    'created_at'   => $now,
                ]);
            }

            // Status log
            $this->orderStatusLogModel->insert([
                'order_id'    => $orderId,
                'from_status' => null,
                'to_status'   => 'waiting_payment',
                'note'        => 'Pesanan berhasil dibuat, menunggu pembayaran pelanggan.',
                'actor_id'    => $userId,
                'created_at'  => $now,
            ]);

            $this->db->transCommit();

            return $this->orderModel->find($orderId);
        } catch (Exception $e) {
            $this->db->transRollback();
            throw $e;
        }
    }

    /**
     * Cancel order & restore stock
     */
    public function cancelOrder(int $orderId, ?string $reason = 'Pesanan dibatalkan', ?int $actorId = null): bool
    {
        $this->db->transBegin();

        try {
            $order = $this->orderModel->find($orderId);
            if (!$order) {
                throw new Exception("Pesanan #{$orderId} tidak ditemukan.");
            }

            if (in_array($order['status'], ['completed', 'cancelled'])) {
                throw new Exception("Pesanan berstatus {$order['status']} tidak dapat dibatalkan.");
            }

            $now = date('Y-m-d H:i:s');
            $items = $this->orderItemModel->where('order_id', $orderId)->findAll();

            foreach ($items as $item) {
                $variant = $this->db->query("SELECT * FROM product_variants WHERE id = ? FOR UPDATE", [$item['variant_id']])->getRowArray();
                if ($variant) {
                    $stockBefore = (int)$variant['stock'];
                    $stockAfter  = $stockBefore + (int)$item['qty'];

                    $this->variantModel->update($item['variant_id'], ['stock' => $stockAfter]);

                    $this->stockMovementModel->insert([
                        'variant_id'   => $item['variant_id'],
                        'type'         => 'cancel',
                        'qty_change'   => (int)$item['qty'],
                        'stock_before' => $stockBefore,
                        'stock_after'  => $stockAfter,
                        'reason'       => "Pembatalan pesanan {$order['order_no']}: {$reason}",
                        'ref_order_id' => $orderId,
                        'admin_id'     => $actorId,
                        'created_at'   => $now,
                    ]);
                }
            }

            $fromStatus = $order['status'];
            $this->orderModel->update($orderId, [
                'status'     => 'cancelled',
                'updated_at' => $now,
            ]);

            $this->orderStatusLogModel->insert([
                'order_id'    => $orderId,
                'from_status' => $fromStatus,
                'to_status'   => 'cancelled',
                'note'        => $reason,
                'actor_id'    => $actorId,
                'created_at'  => $now,
            ]);

            $this->db->transCommit();
            return true;
        } catch (Exception $e) {
            $this->db->transRollback();
            throw $e;
        }
    }

    /**
     * Stock adjustment (Stock Opname)
     */
    public function adjustStock(int $variantId, int $qtyChange, string $reason, int $adminId): array
    {
        $this->db->transBegin();

        try {
            $variant = $this->db->query("SELECT * FROM product_variants WHERE id = ? FOR UPDATE", [$variantId])->getRowArray();
            if (!$variant) {
                throw new Exception("Varian ID {$variantId} tidak ditemukan.");
            }

            $stockBefore = (int)$variant['stock'];
            $stockAfter  = $stockBefore + $qtyChange;

            if ($stockAfter < 0) {
                throw new Exception("Stok tidak boleh bernilai negatif (Hasil kalkulasi: {$stockAfter}).");
            }

            $now = date('Y-m-d H:i:s');
            $this->variantModel->update($variantId, ['stock' => $stockAfter]);

            $this->stockMovementModel->insert([
                'variant_id'   => $variantId,
                'type'         => 'adjust',
                'qty_change'   => $qtyChange,
                'stock_before' => $stockBefore,
                'stock_after'  => $stockAfter,
                'reason'       => $reason,
                'ref_order_id' => null,
                'admin_id'     => $adminId,
                'created_at'   => $now,
            ]);

            $this->db->transCommit();

            return $this->variantModel->find($variantId);
        } catch (Exception $e) {
            $this->db->transRollback();
            throw $e;
        }
    }
}
