<?php

namespace App\Controllers\Admin;

use App\Controllers\BaseController;
use App\Models\VariantModel;
use App\Models\StockMovementModel;
use App\Services\OrderService;
use Config\Database;
use Exception;

class StockController extends BaseController
{
    protected $variantModel;
    protected $stockMovementModel;
    protected $orderService;

    public function __construct()
    {
        $this->variantModel       = new VariantModel();
        $this->stockMovementModel = new StockMovementModel();
        $this->orderService       = new OrderService();
    }

    public function index()
    {
        $db = Database::connect();

        // 1. Daftar varian beserta stok
        $variants = $db->table('product_variants')
            ->select('product_variants.*, products.name as product_name, categories.name as category_name')
            ->join('products', 'products.id = product_variants.product_id')
            ->join('categories', 'categories.id = products.category_id')
            ->where('products.deleted_at', null)
            ->where('product_variants.is_active', 1)
            ->orderBy('products.id', 'DESC')
            ->get()->getResultArray();

        // 2. Riwayat mutasi stok terbaru
        $movements = $db->table('stock_movements')
            ->select('stock_movements.*, product_variants.color, product_variants.size, products.name as product_name, users.name as admin_name')
            ->join('product_variants', 'product_variants.id = stock_movements.variant_id')
            ->join('products', 'products.id = product_variants.product_id')
            ->join('users', 'users.id = stock_movements.admin_id', 'left')
            ->orderBy('stock_movements.id', 'DESC')
            ->limit(20)
            ->get()->getResultArray();

        $data = [
            'title'     => 'Stok & Stock Opname',
            'variants'  => $variants,
            'movements' => $movements,
        ];

        return view('admin/stock/index', $data);
    }

    public function adjust()
    {
        $variantId = (int)$this->request->getPost('variant_id');
        $qtyChange = (int)$this->request->getPost('qty_change');
        $reason    = trim($this->request->getPost('reason'));

        if (empty($reason)) {
            return redirect()->back()->with('error', 'Alasan penyesuaian stok wajib diisi (misal: "Barang rusak -2", "Restock offline +10").');
        }

        if ($qtyChange === 0) {
            return redirect()->back()->with('error', 'Jumlah penyesuaian stok tidak boleh nol.');
        }

        $adminId = session()->get('admin_id');

        try {
            $this->orderService->adjustStock($variantId, $qtyChange, $reason, $adminId);
            return redirect()->to('/admin/stock')->with('success', 'Stok varian berhasil disesuaikan.');
        } catch (Exception $e) {
            return redirect()->back()->with('error', 'Gagal menyesuaikan stok: ' . $e->getMessage());
        }
    }
}
