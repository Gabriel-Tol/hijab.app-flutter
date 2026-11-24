<?php

namespace App\Controllers\Admin;

use App\Controllers\BaseController;
use App\Models\CategoryModel;
use App\Models\ProductModel;
use Config\Database;

class CategoryController extends BaseController
{
    protected $categoryModel;
    protected $productModel;

    public function __construct()
    {
        $this->categoryModel = new CategoryModel();
        $this->productModel  = new ProductModel();
    }

    public function index()
    {
        $db = Database::connect();
        $categories = $db->table('categories')
            ->select('categories.*, COUNT(products.id) as product_count')
            ->join('products', 'products.category_id = categories.id AND products.deleted_at IS NULL', 'left')
            ->groupBy('categories.id')
            ->orderBy('categories.id', 'ASC')
            ->get()->getResultArray();

        $data = [
            'title'      => 'Kategori Produk',
            'categories' => $categories,
        ];

        return view('admin/categories/index', $data);
    }

    public function store()
    {
        $name = trim($this->request->getPost('name'));
        if (empty($name)) {
            return redirect()->back()->with('error', 'Nama kategori wajib diisi.');
        }

        helper('text');
        $slug = url_title($name, '-', true);

        // Check unique slug
        $existing = $this->categoryModel->where('slug', $slug)->first();
        if ($existing) {
            $slug .= '-' . time();
        }

        $this->categoryModel->insert([
            'name'      => $name,
            'slug'      => $slug,
            'is_active' => $this->request->getPost('is_active') ? 1 : 0,
        ]);

        return redirect()->to('/admin/categories')->with('success', 'Kategori baru berhasil ditambahkan.');
    }

    public function update($id)
    {
        $category = $this->categoryModel->find($id);
        if (!$category) {
            return redirect()->back()->with('error', 'Kategori tidak ditemukan.');
        }

        $name = trim($this->request->getPost('name'));
        if (empty($name)) {
            return redirect()->back()->with('error', 'Nama kategori wajib diisi.');
        }

        $this->categoryModel->update($id, [
            'name'      => $name,
            'is_active' => $this->request->getPost('is_active') ? 1 : 0,
        ]);

        return redirect()->to('/admin/categories')->with('success', 'Kategori berhasil diperbarui.');
    }

    public function delete($id)
    {
        $category = $this->categoryModel->find($id);
        if (!$category) {
            return redirect()->back()->with('error', 'Kategori tidak ditemukan.');
        }

        // Cegah hapus bila kategori masih memiliki produk
        $productCount = $this->productModel->where('category_id', $id)->countAllResults();
        if ($productCount > 0) {
            return redirect()->back()->with('error', "Kategori '{$category['name']}' tidak dapat dihapus karena masih digunakan oleh {$productCount} produk.");
        }

        $this->categoryModel->delete($id);
        return redirect()->to('/admin/categories')->with('success', 'Kategori berhasil dihapus.');
    }
}
