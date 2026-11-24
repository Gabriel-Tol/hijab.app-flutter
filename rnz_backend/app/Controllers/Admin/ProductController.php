<?php

namespace App\Controllers\Admin;

use App\Controllers\BaseController;
use App\Models\ProductModel;
use App\Models\CategoryModel;
use App\Models\VariantModel;
use App\Models\ProductImageModel;
use Config\Database;
use Exception;

class ProductController extends BaseController
{
    protected $productModel;
    protected $categoryModel;
    protected $variantModel;
    protected $imageModel;

    public function __construct()
    {
        $this->productModel  = new ProductModel();
        $this->categoryModel = new CategoryModel();
        $this->variantModel  = new VariantModel();
        $this->imageModel    = new ProductImageModel();
    }

    public function index()
    {
        $db = Database::connect();
        $keyword    = $this->request->getGet('search');
        $categoryId = $this->request->getGet('category_id');

        $builder = $db->table('products')
            ->select('products.*, categories.name as category_name, COALESCE(SUM(product_variants.stock), 0) as total_stock, (SELECT file_path FROM product_images WHERE product_images.product_id = products.id ORDER BY sort_order ASC LIMIT 1) as thumbnail')
            ->join('categories', 'categories.id = products.category_id', 'left')
            ->join('product_variants', 'product_variants.product_id = products.id AND product_variants.is_active = 1', 'left')
            ->where('products.deleted_at', null)
            ->groupBy('products.id')
            ->orderBy('products.id', 'DESC');

        if (!empty($keyword)) {
            $builder->like('products.name', $keyword);
        }

        if (!empty($categoryId)) {
            $builder->where('products.category_id', $categoryId);
        }

        $products   = $builder->get()->getResultArray();
        $categories = $this->categoryModel->where('is_active', 1)->findAll();

        $data = [
            'title'      => 'Katalog Produk & Varian',
            'products'   => $products,
            'categories' => $categories,
            'keyword'    => $keyword,
            'categoryId' => $categoryId,
        ];

        return view('admin/products/index', $data);
    }

    public function create()
    {
        $categories = $this->categoryModel->where('is_active', 1)->findAll();
        $data = [
            'title'      => 'Tambah Produk Baru',
            'categories' => $categories,
        ];

        return view('admin/products/create', $data);
    }

    public function store()
    {
        $rules = [
            'name'        => 'required|min_length[3]|max_length[150]',
            'category_id' => 'required|is_natural_no_zero',
            'price'       => 'required|is_natural_no_zero',
        ];

        if (!$this->validate($rules)) {
            return redirect()->back()->withInput()->with('errors', $this->validator->getErrors());
        }

        $name       = trim($this->request->getPost('name'));
        $categoryId = (int)$this->request->getPost('category_id');
        $price      = (int)$this->request->getPost('price');
        $desc       = $this->request->getPost('description');
        $isActive   = $this->request->getPost('is_active') ? 1 : 0;

        helper('text');
        $slug = url_title($name, '-', true);
        if ($this->productModel->where('slug', $slug)->first()) {
            $slug .= '-' . time();
        }

        $db = Database::connect();
        $db->transBegin();

        try {
            $productId = $this->productModel->insert([
                'category_id' => $categoryId,
                'name'        => $name,
                'slug'        => $slug,
                'description' => $desc,
                'price'       => $price,
                'is_active'   => $isActive,
            ]);

            // 1. Simpan Varian Produk
            $colors = $this->request->getPost('variant_color') ?? [];
            $sizes  = $this->request->getPost('variant_size') ?? [];
            $stocks = $this->request->getPost('variant_stock') ?? [];
            $skus   = $this->request->getPost('variant_sku') ?? [];

            if (empty($colors)) {
                // Default varian jika tidak diisi
                $this->variantModel->insert([
                    'product_id' => $productId,
                    'color'      => 'Standar',
                    'size'       => 'All Size',
                    'stock'      => 0,
                    'is_active'  => 1,
                ]);
            } else {
                foreach ($colors as $i => $color) {
                    if (!empty(trim($color))) {
                        $this->variantModel->insert([
                            'product_id' => $productId,
                            'color'      => trim($color),
                            'size'       => !empty($sizes[$i]) ? trim($sizes[$i]) : 'All Size',
                            'sku'        => !empty($skus[$i]) ? trim($skus[$i]) : null,
                            'stock'      => isset($stocks[$i]) ? (int)$stocks[$i] : 0,
                            'is_active'  => 1,
                        ]);
                    }
                }
            }

            // 2. Upload Gambar Produk (1 - 5 foto)
            $images = $this->request->getFileMultiple('images');
            if ($images) {
                $sort = 1;
                foreach ($images as $img) {
                    if ($img->isValid() && !$img->hasMoved()) {
                        // Pastikan tipe file gambar valid
                        $ext = $img->getExtension();
                        if (in_array(strtolower($ext), ['jpg', 'jpeg', 'png', 'webp'])) {
                            $newName = $img->getRandomName();
                            $img->move(FCPATH . 'uploads/products', $newName);

                            $this->imageModel->insert([
                                'product_id' => $productId,
                                'file_path'  => 'uploads/products/' . $newName,
                                'sort_order' => $sort++,
                            ]);
                        }
                    }
                }
            }

            $db->transCommit();
            return redirect()->to('/admin/products')->with('success', 'Produk berhasil ditambahkan.');
        } catch (Exception $e) {
            $db->transRollback();
            return redirect()->back()->withInput()->with('error', 'Gagal menambahkan produk: ' . $e->getMessage());
        }
    }

    public function edit($id)
    {
        $product = $this->productModel->find($id);
        if (!$product) {
            return redirect()->to('/admin/products')->with('error', 'Produk tidak ditemukan.');
        }

        $categories = $this->categoryModel->where('is_active', 1)->findAll();
        $variants   = $this->variantModel->where('product_id', $id)->findAll();
        $images     = $this->imageModel->where('product_id', $id)->orderBy('sort_order', 'ASC')->findAll();

        $data = [
            'title'      => 'Ubah Produk: ' . $product['name'],
            'product'    => $product,
            'categories' => $categories,
            'variants'   => $variants,
            'images'     => $images,
        ];

        return view('admin/products/edit', $data);
    }

    public function update($id)
    {
        $product = $this->productModel->find($id);
        if (!$product) {
            return redirect()->to('/admin/products')->with('error', 'Produk tidak ditemukan.');
        }

        $rules = [
            'name'        => 'required|min_length[3]|max_length[150]',
            'category_id' => 'required|is_natural_no_zero',
            'price'       => 'required|is_natural_no_zero',
        ];

        if (!$this->validate($rules)) {
            return redirect()->back()->withInput()->with('errors', $this->validator->getErrors());
        }

        $db = Database::connect();
        $db->transBegin();

        try {
            $this->productModel->update($id, [
                'name'        => trim($this->request->getPost('name')),
                'category_id' => (int)$this->request->getPost('category_id'),
                'price'       => (int)$this->request->getPost('price'),
                'description' => $this->request->getPost('description'),
                'is_active'   => $this->request->getPost('is_active') ? 1 : 0,
            ]);

            // Update varian yang sudah ada
            $existingVariantIds = $this->request->getPost('existing_variant_id') ?? [];
            $existingColors     = $this->request->getPost('existing_variant_color') ?? [];
            $existingSizes      = $this->request->getPost('existing_variant_size') ?? [];
            $existingStocks     = $this->request->getPost('existing_variant_stock') ?? [];
            $existingSkus       = $this->request->getPost('existing_variant_sku') ?? [];

            foreach ($existingVariantIds as $i => $varId) {
                $this->variantModel->update($varId, [
                    'color' => trim($existingColors[$i]),
                    'size'  => !empty($existingSizes[$i]) ? trim($existingSizes[$i]) : 'All Size',
                    'sku'   => !empty($existingSkus[$i]) ? trim($existingSkus[$i]) : null,
                    'stock' => (int)$existingStocks[$i],
                ]);
            }

            // Tambah varian baru jika ada
            $newColors = $this->request->getPost('new_variant_color') ?? [];
            $newSizes  = $this->request->getPost('new_variant_size') ?? [];
            $newStocks = $this->request->getPost('new_variant_stock') ?? [];
            $newSkus   = $this->request->getPost('new_variant_sku') ?? [];

            foreach ($newColors as $i => $nColor) {
                if (!empty(trim($nColor))) {
                    $this->variantModel->insert([
                        'product_id' => $id,
                        'color'      => trim($nColor),
                        'size'       => !empty($newSizes[$i]) ? trim($newSizes[$i]) : 'All Size',
                        'sku'        => !empty($newSkus[$i]) ? trim($newSkus[$i]) : null,
                        'stock'      => isset($newStocks[$i]) ? (int)$newStocks[$i] : 0,
                        'is_active'  => 1,
                    ]);
                }
            }

            // Upload gambar baru
            $images = $this->request->getFileMultiple('images');
            if ($images) {
                $currentMaxSort = $this->imageModel->where('product_id', $id)->selectMax('sort_order')->first()['sort_order'] ?? 0;
                $sort = $currentMaxSort + 1;

                foreach ($images as $img) {
                    if ($img->isValid() && !$img->hasMoved()) {
                        $ext = $img->getExtension();
                        if (in_array(strtolower($ext), ['jpg', 'jpeg', 'png', 'webp'])) {
                            $newName = $img->getRandomName();
                            $img->move(FCPATH . 'uploads/products', $newName);

                            $this->imageModel->insert([
                                'product_id' => $id,
                                'file_path'  => 'uploads/products/' . $newName,
                                'sort_order' => $sort++,
                            ]);
                        }
                    }
                }
            }

            $db->transCommit();
            return redirect()->to('/admin/products')->with('success', 'Produk berhasil diperbarui.');
        } catch (Exception $e) {
            $db->transRollback();
            return redirect()->back()->withInput()->with('error', 'Gagal memperbarui produk: ' . $e->getMessage());
        }
    }

    public function delete($id)
    {
        $product = $this->productModel->find($id);
        if (!$product) {
            return redirect()->to('/admin/products')->with('error', 'Produk tidak ditemukan.');
        }

        // Soft delete
        $this->productModel->delete($id);
        return redirect()->to('/admin/products')->with('success', 'Produk berhasil dihapus (soft-delete).');
    }

    public function deleteImage($imageId)
    {
        $image = $this->imageModel->find($imageId);
        if ($image) {
            $filePath = FCPATH . $image['file_path'];
            if (is_file($filePath)) {
                @unlink($filePath);
            }
            $this->imageModel->delete($imageId);
        }
        return redirect()->back()->with('success', 'Foto produk berhasil dihapus.');
    }
}
