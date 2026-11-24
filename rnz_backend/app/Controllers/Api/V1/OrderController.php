<?php

namespace App\Controllers\Api\V1;

use App\Controllers\Api\BaseApiController;
use App\Models\OrderModel;
use App\Models\OrderItemModel;
use App\Models\PaymentProofModel;
use App\Models\ShipmentModel;
use App\Models\OrderStatusLogModel;
use App\Services\OrderService;
use Config\Database;
use Exception;

class OrderController extends BaseApiController
{
    protected $orderService;
    protected $orderModel;
    protected $orderItemModel;
    protected $proofModel;
    protected $shipmentModel;
    protected $logModel;

    public function __construct()
    {
        $this->orderService   = new OrderService();
        $this->orderModel     = new OrderModel();
        $this->orderItemModel = new OrderItemModel();
        $this->proofModel     = new PaymentProofModel();
        $this->shipmentModel  = new ShipmentModel();
        $this->logModel       = new OrderStatusLogModel();
    }

    public function checkout()
    {
        $user = $this->getAuthenticatedUser();
        if (!$user) {
            return $this->respondWithError('Otentikasi diperlukan.', 401);
        }

        $items         = $this->request->getVar('items');
        $address       = $this->request->getVar('address');
        $paymentMethod = $this->request->getVar('payment_method');
        $shippingCost  = (int)($this->request->getVar('shipping_cost') ?? 0);

        if (empty($items) || !is_array($items)) {
            return $this->respondWithError('Item belanja tidak boleh kosong.', 422);
        }

        if (empty($address) || !is_array($address)) {
            return $this->respondWithError('Alamat pengiriman wajib diisi.', 422);
        }

        if (empty($paymentMethod) || !is_array($paymentMethod)) {
            return $this->respondWithError('Metode pembayaran wajib dipilih.', 422);
        }

        try {
            $order = $this->orderService->createOrder(
                (int)$user->sub,
                $items,
                $address,
                $paymentMethod,
                $shippingCost
            );

            // Ambil rincian item pesanan
            $order['items'] = $this->orderItemModel->where('order_id', $order['id'])->findAll();

            return $this->respondWithSuccess($order, 'Pesanan berhasil dibuat. Silakan lakukan pembayaran.', 201);
        } catch (Exception $e) {
            return $this->respondWithError('Checkout gagal: ' . $e->getMessage(), 400);
        }
    }

    public function getOrders()
    {
        $user = $this->getAuthenticatedUser();
        if (!$user) {
            return $this->respondWithError('Otentikasi diperlukan.', 401);
        }

        $status  = $this->request->getGet('status');
        $builder = $this->orderModel->where('user_id', $user->sub)->orderBy('id', 'DESC');

        if (!empty($status)) {
            $builder->where('status', $status);
        }

        $orders = $builder->findAll();

        foreach ($orders as &$order) {
            $order['items']            = $this->orderItemModel->where('order_id', $order['id'])->findAll();
            $order['shipment']         = $this->shipmentModel->where('order_id', $order['id'])->first();
            $order['address_snapshot'] = json_decode($order['address_snapshot'] ?? '{}', true);
            $order['payment_snapshot'] = json_decode($order['payment_method_snapshot'] ?? '{}', true);
        }

        return $this->respondWithSuccess($orders, 'Daftar pesanan berhasil dimuat.');
    }

    public function getOrderDetail($id)
    {
        $user = $this->getAuthenticatedUser();
        if (!$user) {
            return $this->respondWithError('Otentikasi diperlukan.', 401);
        }

        $order = $this->orderModel->where('id', $id)->where('user_id', $user->sub)->first();
        if (!$order) {
            return $this->respondWithError('Pesanan tidak ditemukan.', 404);
        }

        $baseUrl = base_url();

        $items   = $this->orderItemModel->where('order_id', $id)->findAll();
        $proofs  = $this->proofModel->where('order_id', $id)->orderBy('id', 'DESC')->findAll();
        $shipment = $this->shipmentModel->where('order_id', $id)->first();
        $logs    = $this->logModel->where('order_id', $id)->orderBy('id', 'ASC')->findAll();

        foreach ($proofs as &$p) {
            $p['file_url'] = rtrim($baseUrl, '/') . '/' . ltrim($p['file_path'], '/');
        }

        $order['items']            = $items;
        $order['proofs']           = $proofs;
        $order['shipment']         = $shipment;
        $order['status_logs']      = $logs;
        $order['address_snapshot'] = json_decode($order['address_snapshot'] ?? '{}', true);
        $order['payment_snapshot'] = json_decode($order['payment_method_snapshot'] ?? '{}', true);

        return $this->respondWithSuccess($order, 'Detail pesanan berhasil dimuat.');
    }

    public function uploadPaymentProof($id)
    {
        $user = $this->getAuthenticatedUser();
        if (!$user) {
            return $this->respondWithError('Otentikasi diperlukan.', 401);
        }

        $order = $this->orderModel->where('id', $id)->where('user_id', $user->sub)->first();
        if (!$order) {
            return $this->respondWithError('Pesanan tidak ditemukan.', 404);
        }

        if (!in_array($order['status'], ['waiting_payment', 'verifying_payment'])) {
            return $this->respondWithError("Pesanan dengan status '{$order['status']}' tidak dapat mengunggah bukti bayar.", 400);
        }

        $file = $this->request->getFile('proof');
        if (!$file || !$file->isValid()) {
            return $this->respondWithError('File bukti transfer wajib diunggah (JPG/PNG/WEBP maks 5MB).', 422);
        }

        $ext = strtolower($file->getExtension());
        if (!in_array($ext, ['jpg', 'jpeg', 'png', 'webp'])) {
            return $this->respondWithError('Format gambar harus JPG, PNG, atau WEBP.', 422);
        }

        $db = Database::connect();
        $db->transBegin();

        try {
            $newName = $file->getRandomName();
            $file->move(FCPATH . 'uploads/proofs', $newName);
            $filePath = 'uploads/proofs/' . $newName;

            $now = date('Y-m-d H:i:s');
            $this->proofModel->insert([
                'order_id'   => $id,
                'file_path'  => $filePath,
                'status'     => 'pending',
                'created_at' => $now,
            ]);

            $fromStatus = $order['status'];
            $this->orderModel->update($id, [
                'status'     => 'verifying_payment',
                'updated_at' => $now,
            ]);

            $this->logModel->insert([
                'order_id'    => $id,
                'from_status' => $fromStatus,
                'to_status'   => 'verifying_payment',
                'note'        => 'Pelanggan telah mengunggah bukti pembayaran baru.',
                'actor_id'    => $user->sub,
                'created_at'  => $now,
            ]);

            $db->transCommit();

            $updatedOrder = $this->orderModel->find($id);
            return $this->respondWithSuccess($updatedOrder, 'Bukti pembayaran berhasil diunggah. Tim admin akan segera memverifikasi pesanan Anda.');
        } catch (Exception $e) {
            $db->transRollback();
            return $this->respondWithError('Gagal mengunggah bukti bayar: ' . $e->getMessage(), 500);
        }
    }

    public function cancelOrder($id)
    {
        $user = $this->getAuthenticatedUser();
        if (!$user) {
            return $this->respondWithError('Otentikasi diperlukan.', 401);
        }

        $order = $this->orderModel->where('id', $id)->where('user_id', $user->sub)->first();
        if (!$order) {
            return $this->respondWithError('Pesanan tidak ditemukan.', 404);
        }

        if ($order['status'] !== 'waiting_payment') {
            return $this->respondWithError("Hanya pesanan yang belum dibayar (Menunggu Pembayaran) yang dapat dibatalkan mandiri oleh pelanggan.", 400);
        }

        $reason = trim($this->request->getVar('reason') ?? 'Dibatalkan oleh pelanggan');

        try {
            $this->orderService->cancelOrder($id, $reason, (int)$user->sub);
            return $this->respondWithSuccess(null, 'Pesanan berhasil dibatalkan dan stok dikembalikan.');
        } catch (Exception $e) {
            return $this->respondWithError('Gagal membatalkan pesanan: ' . $e->getMessage(), 400);
        }
    }
}
