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
     * Hitung tarif ongkir resmi berdasarkan tabel shipping_rates di database
     */
    public function calculateShippingCost(array $addressData): int
    {
        $shippingRateId = $addressData['shipping_rate_id'] ?? null;
        if (!empty($shippingRateId)) {
            $rate = $this->db->table('shipping_rates')
                ->where('id', (int)$shippingRateId)
                ->where('is_active', 1)
                ->get()->getRowArray();
            if ($rate) {
                return (int)$rate['cost'];
            }
        }

        $city = trim($addressData['city'] ?? '');
        if (!empty($city)) {
            // Pencarian nama wilayah persis (case-insensitive)
            $rate = $this->db->table('shipping_rates')
                ->where('is_active', 1)
                ->where('LOWER(region_name)', strtolower($city))
                ->get()->getRowArray();

            if (!$rate) {
                // Pencarian kemiripan nama kota (misal "Kota Pontianak" cocok dengan "Kota Pontianak (Flat)")
                $cleanCity = trim(preg_replace('/^(kota|kabupaten|kab\.)\s+/i', '', $city));
                $rate = $this->db->table('shipping_rates')
                    ->where('is_active', 1)
                    ->groupStart()
                        ->like('region_name', $city)
                        ->orLike('region_name', $cleanCity)
                    ->groupEnd()
                    ->orderBy('cost', 'ASC')
                    ->get()->getRowArray();
            }

            if ($rate) {
                return (int)$rate['cost'];
            }
        }

        // Default flat fallback jika wilayah belum terdaftar spesifik
        $defaultRate = $this->db->table('shipping_rates')
            ->where('is_active', 1)
            ->orderBy('cost', 'ASC')
            ->get()->getRowArray();

        return $defaultRate ? (int)$defaultRate['cost'] : 15000;
    }

    /**
     * Atomic checkout with row-locking
     */
    public function createOrder(
        int $userId,
        array $items,
        array $addressData,
        array $paymentMethodData,
        ?int $shippingCost = null
    ): array {
        if (empty($items)) {
            throw new Exception('Item pesanan tidak boleh kosong.');
        }

        // Hitung biaya ongkir server-side secara otoritatif jika tidak dispesifikasikan oleh sistem internal
        if ($shippingCost === null || $shippingCost <= 0) {
            $shippingCost = $this->calculateShippingCost($addressData);
        }

        $this->db->transBegin();

        try {
            $subtotal = 0;
            $preparedItems = [];

            foreach ($items as $item) {
                $qty = (int)($item['qty'] ?? 1);

                if ($qty <= 0) {
                    throw new Exception('Jumlah item harus lebih dari nol.');
                }

                // Resolve variant: by numeric ID, by SKU, or graceful fallback
                $variantId = null;
                if (!empty($item['variant_id']) && is_numeric($item['variant_id'])) {
                    $candidate = $this->db->table('product_variants')->where('id', (int)$item['variant_id'])->get()->getRowArray();
                    if ($candidate) {
                        $variantId = (int)$candidate['id'];
                    }
                }
                if (!$variantId && !empty($item['sku'])) {
                    $foundBySku = $this->db->table('product_variants')->where('sku', $item['sku'])->get()->getRowArray();
                    if ($foundBySku) {
                        $variantId = (int)$foundBySku['id'];
                    }
                }
                if (!$variantId) {
                    $fallback = $this->db->table('product_variants')->where('is_active', 1)->orderBy('id', 'ASC')->get()->getRowArray();
                    if ($fallback) {
                        $variantId = (int)$fallback['id'];
                    }
                }

                // To ensure row lock in MySQL
                $lockedVariant = $this->db->query("SELECT * FROM product_variants WHERE id = ? FOR UPDATE", [$variantId])->getRowArray();

                if (!$lockedVariant) {
                    throw new Exception("Varian produk tidak ditemukan.");
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
