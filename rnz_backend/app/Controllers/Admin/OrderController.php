<?php

namespace App\Controllers\Admin;

use App\Controllers\BaseController;
use App\Models\OrderModel;
use App\Models\OrderItemModel;
use App\Models\PaymentProofModel;
use App\Models\ShipmentModel;
use App\Models\OrderStatusLogModel;
use Config\Database;
use Exception;

class OrderController extends BaseController
{
    protected $orderModel;
    protected $orderItemModel;
    protected $proofModel;
    protected $shipmentModel;
    protected $logModel;

    public function __construct()
    {
        $this->orderModel     = new OrderModel();
        $this->orderItemModel = new OrderItemModel();
        $this->proofModel     = new PaymentProofModel();
        $this->shipmentModel  = new ShipmentModel();
        $this->logModel       = new OrderStatusLogModel();
    }

    public function index()
    {
        $db = Database::connect();
        $statusTab = $this->request->getGet('status') ?? 'all';
        $keyword   = $this->request->getGet('search');

        $builder = $db->table('orders')
            ->select('orders.*, users.name as customer_name, users.phone as customer_phone')
            ->join('users', 'users.id = orders.user_id')
            ->orderBy('orders.id', 'DESC');

        if ($statusTab !== 'all') {
            $builder->where('orders.status', $statusTab);
        }

        if (!empty($keyword)) {
            $builder->groupStart()
                ->like('orders.order_no', $keyword)
                ->orLike('users.name', $keyword)
                ->groupEnd();
        }

        $orders = $builder->get()->getResultArray();

        // Counts per status
        $counts = [
            'all'               => $this->orderModel->countAllResults(),
            'waiting_payment'   => $this->orderModel->where('status', 'waiting_payment')->countAllResults(),
            'verifying_payment' => $this->orderModel->where('status', 'verifying_payment')->countAllResults(),
            'processing'        => $this->orderModel->where('status', 'processing')->countAllResults(),
            'shipped'           => $this->orderModel->where('status', 'shipped')->countAllResults(),
            'completed'         => $this->orderModel->where('status', 'completed')->countAllResults(),
            'cancelled'         => $this->orderModel->where('status', 'cancelled')->countAllResults(),
        ];

        $data = [
            'title'     => 'Kelola Pesanan & Verifikasi',
            'orders'    => $orders,
            'statusTab' => $statusTab,
            'keyword'   => $keyword,
            'counts'    => $counts,
        ];

        return view('admin/orders/index', $data);
    }

    public function show($id)
    {
        $db = Database::connect();
        $order = $db->table('orders')
            ->select('orders.*, users.name as customer_name, users.email as customer_email, users.phone as customer_phone')
            ->join('users', 'users.id = orders.user_id')
            ->where('orders.id', $id)
            ->get()->getRowArray();

        if (!$order) {
            return redirect()->to('/admin/orders')->with('error', 'Pesanan tidak ditemukan.');
        }

        $items    = $this->orderItemModel->where('order_id', $id)->findAll();
        $proofs   = $this->proofModel->where('order_id', $id)->orderBy('id', 'DESC')->findAll();
        $shipment = $this->shipmentModel->where('order_id', $id)->first();

        $logs = $db->table('order_status_logs')
            ->select('order_status_logs.*, users.name as actor_name')
            ->join('users', 'users.id = order_status_logs.actor_id', 'left')
            ->where('order_id', $id)
            ->orderBy('id', 'ASC')
            ->get()->getResultArray();

        $addressSnapshot = json_decode($order['address_snapshot'], true) ?? [];
        $paymentSnapshot = json_decode($order['payment_method_snapshot'], true) ?? [];

        $data = [
            'title'           => 'Detail Pesanan #' . $order['order_no'],
            'order'           => $order,
            'items'           => $items,
            'proofs'          => $proofs,
            'shipment'        => $shipment,
            'logs'            => $logs,
            'addressSnapshot' => $addressSnapshot,
            'paymentSnapshot' => $paymentSnapshot,
        ];

        return view('admin/orders/show', $data);
    }

    public function approvePayment($id)
    {
        $order = $this->orderModel->find($id);
        if (!$order) {
            return redirect()->back()->with('error', 'Pesanan tidak ditemukan.');
        }

        if ($order['status'] !== 'verifying_payment') {
            return redirect()->back()->with('error', 'Status pesanan tidak berada dalam tahap verifikasi.');
        }

        $adminId = session()->get('admin_id');
        $now     = date('Y-m-d H:i:s');

        $db = Database::connect();
        $db->transBegin();

        try {
            // Update latest proof
            $latestProof = $this->proofModel->where('order_id', $id)->orderBy('id', 'DESC')->first();
            if ($latestProof) {
                $this->proofModel->update($latestProof['id'], [
                    'status'      => 'approved',
                    'reviewed_by' => $adminId,
                    'reviewed_at' => $now,
                ]);
            }

            // Update order status to processing
            $this->orderModel->update($id, [
                'status'     => 'processing',
                'updated_at' => $now,
            ]);

            // Add status log
            $this->logModel->insert([
                'order_id'    => $id,
                'from_status' => 'verifying_payment',
                'to_status'   => 'processing',
                'note'        => 'Pembayaran diverifikasi dan disetujui oleh admin.',
                'actor_id'    => $adminId,
                'created_at'  => $now,
            ]);

            $db->transCommit();
            return redirect()->back()->with('success', 'Pembayaran pesanan berhasil disetujui. Pesanan siap diproses dan dikirim.');
        } catch (Exception $e) {
            $db->transRollback();
            return redirect()->back()->with('error', 'Gagal memverifikasi pembayaran: ' . $e->getMessage());
        }
    }

    public function rejectPayment($id)
    {
        $order = $this->orderModel->find($id);
        if (!$order) {
            return redirect()->back()->with('error', 'Pesanan tidak ditemukan.');
        }

        $reason = trim($this->request->getPost('reject_reason'));
        if (empty($reason)) {
            return redirect()->back()->with('error', 'Alasan penolakan bukti bayar wajib diisi agar pelanggan mengetahui apa yang perlu diperbaiki.');
        }

        $adminId = session()->get('admin_id');
        $now     = date('Y-m-d H:i:s');

        $db = Database::connect();
        $db->transBegin();

        try {
            $latestProof = $this->proofModel->where('order_id', $id)->orderBy('id', 'DESC')->first();
            if ($latestProof) {
                $this->proofModel->update($latestProof['id'], [
                    'status'        => 'rejected',
                    'reject_reason' => $reason,
                    'reviewed_by'   => $adminId,
                    'reviewed_at'   => $now,
                ]);
            }

            // Kembalikan status ke waiting_payment agar pelanggan bisa unggah ulang
            $this->orderModel->update($id, [
                'status'     => 'waiting_payment',
                'updated_at' => $now,
            ]);

            $this->logModel->insert([
                'order_id'    => $id,
                'from_status' => 'verifying_payment',
                'to_status'   => 'waiting_payment',
                'note'        => 'Bukti pembayaran ditolak: ' . $reason,
                'actor_id'    => $adminId,
                'created_at'  => $now,
            ]);

            $db->transCommit();
            return redirect()->back()->with('success', 'Bukti bayar ditolak. Pelanggan dapat melihat alasan dan mengunggah ulang bukti baru.');
        } catch (Exception $e) {
            $db->transRollback();
            return redirect()->back()->with('error', 'Gagal menolak bukti pembayaran: ' . $e->getMessage());
        }
    }

    public function submitShipment($id)
    {
        $order = $this->orderModel->find($id);
        if (!$order) {
            return redirect()->back()->with('error', 'Pesanan tidak ditemukan.');
        }

        if ($order['status'] !== 'processing') {
            return redirect()->back()->with('error', 'Pesanan harus berstatus diproses sebelum diinput nomor resi.');
        }

        $courier    = trim($this->request->getPost('courier'));
        $trackingNo = trim($this->request->getPost('tracking_no'));

        if (empty($courier) || empty($trackingNo)) {
            return redirect()->back()->with('error', 'Nama ekspedisi dan nomor resi wajib diisi.');
        }

        $adminId = session()->get('admin_id');
        $now     = date('Y-m-d H:i:s');

        $db = Database::connect();
        $db->transBegin();

        try {
            $this->shipmentModel->insert([
                'order_id'    => $id,
                'courier'     => $courier,
                'tracking_no' => $trackingNo,
                'shipped_at'  => $now,
                'created_at'  => $now,
            ]);

            $this->orderModel->update($id, [
                'status'     => 'shipped',
                'updated_at' => $now,
            ]);

            $this->logModel->insert([
                'order_id'    => $id,
                'from_status' => 'processing',
                'to_status'   => 'shipped',
                'note'        => "Pesanan diserahkan ke ekspedisi {$courier} dengan no resi {$trackingNo}.",
                'actor_id'    => $adminId,
                'created_at'  => $now,
            ]);

            $db->transCommit();
            return redirect()->back()->with('success', "Resi berhasil diinput. Status pesanan kini DIKIRIM ({$trackingNo}).");
        } catch (Exception $e) {
            $db->transRollback();
            return redirect()->back()->with('error', 'Gagal menyimpan resi pengiriman: ' . $e->getMessage());
        }
    }
}
