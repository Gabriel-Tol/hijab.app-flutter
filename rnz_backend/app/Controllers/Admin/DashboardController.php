<?php

namespace App\Controllers\Admin;

use App\Controllers\BaseController;
use App\Models\OrderModel;
use App\Models\VariantModel;
use App\Models\ProductModel;
use Config\Database;

class DashboardController extends BaseController
{
    public function index()
    {
        $db = Database::connect();
        $orderModel = new OrderModel();
        $variantModel = new VariantModel();

        // 1. Omzet bulan ini (status: processing, shipped, completed)
        $startOfMonth = date('Y-m-01 00:00:00');
        $endOfMonth   = date('Y-m-t 23:59:59');

        $revenueRow = $db->table('orders')
            ->selectSum('total', 'omzet')
            ->whereIn('status', ['processing', 'shipped', 'completed'])
            ->where('created_at >=', $startOfMonth)
            ->where('created_at <=', $endOfMonth)
            ->get()->getRow();
        $monthlyRevenue = (int)($revenueRow->omzet ?? 0);

        // 2. Pesanan perlu verifikasi bukti bayar
        $pendingVerificationCount = $orderModel->where('status', 'verifying_payment')->countAllResults();

        // 3. Pesanan perlu dikirim
        $processingCount = $orderModel->where('status', 'processing')->countAllResults();

        // 4. Stok menipis (<= 3)
        $lowStockCount = $variantModel->where('stock <=', 3)->where('is_active', 1)->countAllResults();

        // 5. 5 Pesanan terbaru
        $recentOrders = $db->table('orders')
            ->select('orders.*, users.name as customer_name')
            ->join('users', 'users.id = orders.user_id')
            ->orderBy('orders.id', 'DESC')
            ->limit(5)
            ->get()->getResultArray();

        // 6. Daftar varian dengan stok <= 3
        $lowStockVariants = $db->table('product_variants')
            ->select('product_variants.*, products.name as product_name')
            ->join('products', 'products.id = product_variants.product_id')
            ->where('product_variants.stock <=', 3)
            ->where('product_variants.is_active', 1)
            ->limit(5)
            ->get()->getResultArray();

        $data = [
            'title'                    => 'Dashboard Ringkasan',
            'monthlyRevenue'           => $monthlyRevenue,
            'pendingVerificationCount' => $pendingVerificationCount,
            'processingCount'          => $processingCount,
            'lowStockCount'            => $lowStockCount,
            'recentOrders'             => $recentOrders,
            'lowStockVariants'         => $lowStockVariants,
        ];

        return view('admin/dashboard/index', $data);
    }
}
