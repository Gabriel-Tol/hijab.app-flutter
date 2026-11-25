<?php

namespace App\Controllers\Api\V1;

use App\Controllers\Api\BaseApiController;
use App\Models\CategoryModel;
use App\Models\ProductModel;
use App\Models\VariantModel;
use App\Models\ProductImageModel;
use Config\Database;

class CatalogController extends BaseApiController
{
    protected $categoryModel;
    protected $productModel;
    protected $variantModel;
    protected $imageModel;

    public function __construct()
    {
        $this->categoryModel = new CategoryModel();
        $this->productModel  = new ProductModel();
        $this->variantModel  = new VariantModel();
        $this->imageModel    = new ProductImageModel();
    }

    public function getCategories()
    {
        $db = Database::connect();
        $categories = $db->table('categories')
            ->select('categories.*, COUNT(products.id) as product_count')
            ->join('products', 'products.category_id = categories.id AND products.is_active = 1 AND products.deleted_at IS NULL', 'left')
            ->where('categories.is_active', 1)
            ->groupBy('categories.id')
            ->orderBy('categories.name', 'ASC')
            ->get()->getResultArray();

        return $this->respondWithSuccess($categories, 'Daftar kategori produk berhasil dimuat.');
    }

    public function getProducts()
    {
        $db = Database::connect();
        $categoryId = $this->request->getGet('category_id');
        $search     = $this->request->getGet('search');
        $limit      = (int)($this->request->getGet('limit') ?? 20);
        $page       = (int)($this->request->getGet('page') ?? 1);
        $offset     = ($page - 1) * $limit;

        $builder = $db->table('products')
            ->select('products.id, products.category_id, products.name, products.slug, products.description, products.price, products.created_at, categories.name as category_name, (SELECT file_path FROM product_images WHERE product_images.product_id = products.id ORDER BY sort_order ASC LIMIT 1) as thumbnail, COALESCE(SUM(product_variants.stock), 0) as total_stock')
            ->join('categories', 'categories.id = products.category_id', 'left')
            ->join('product_variants', 'product_variants.product_id = products.id AND product_variants.is_active = 1', 'left')
            ->where('products.is_active', 1)
            ->where('products.deleted_at', null)
            ->groupBy(['products.id', 'categories.name'])
            ->orderBy('products.id', 'DESC');

        if (!empty($categoryId)) {
            $builder->where('products.category_id', (int)$categoryId);
        }

        if (!empty($search)) {
            $builder->like('products.name', $search);
        }

        $total = $builder->countAllResults(false);
        $products = $builder->limit($limit, $offset)->get()->getResultArray();

        // Enrich each product with images, variants, and full thumbnail URL
        $baseUrl = base_url();
        $productIds = array_column($products, 'id');

        // Batch-load variants & images for all returned products
        $allVariants = [];
        $allImages   = [];
        if (!empty($productIds)) {
            $rows = $db->table('product_variants')
                ->whereIn('product_id', $productIds)
                ->where('is_active', 1)
                ->get()->getResultArray();
            foreach ($rows as $v) {
                $v['stock'] = (int)$v['stock'];
                $allVariants[$v['product_id']][] = $v;
            }

            $imgRows = $db->table('product_images')
                ->whereIn('product_id', $productIds)
                ->orderBy('sort_order', 'ASC')
                ->get()->getResultArray();
            foreach ($imgRows as $img) {
                $allImages[$img['product_id']][] = rtrim($baseUrl, '/') . '/' . ltrim($img['file_path'], '/');
            }
        }

        foreach ($products as &$p) {
            $p['thumbnail_url'] = !empty($p['thumbnail']) ? rtrim($baseUrl, '/') . '/' . ltrim($p['thumbnail'], '/') : null;
            $p['price']         = (int)$p['price'];
            $p['total_stock']   = (int)$p['total_stock'];
            $p['variants']      = $allVariants[$p['id']] ?? [];
            $p['images']        = $allImages[$p['id']] ?? [];
        }

        return $this->respondWithSuccess([
            'products'     => $products,
            'total'        => $total,
            'current_page' => $page,
            'per_page'     => $limit,
        ], 'Katalog produk berhasil dimuat.');
    }

    public function getProductDetail($identifier)
    {
        $db = Database::connect();
        $builder = $db->table('products')
            ->select('products.*, categories.name as category_name')
            ->join('categories', 'categories.id = products.category_id', 'left')
            ->where('products.is_active', 1)
            ->where('products.deleted_at', null);

        if (is_numeric($identifier)) {
            $builder->where('products.id', (int)$identifier);
        } else {
            $builder->where('products.slug', $identifier);
        }

        $product = $builder->get()->getRowArray();

        if (!$product) {
            return $this->respondWithError('Produk tidak ditemukan atau sudah tidak aktif.', 404);
        }

        $baseUrl = base_url();

        // Ambil galeri gambar
        $images = $this->imageModel->where('product_id', $product['id'])
            ->orderBy('sort_order', 'ASC')
            ->findAll();

        foreach ($images as &$img) {
            $img['url'] = rtrim($baseUrl, '/') . '/' . ltrim($img['file_path'], '/');
        }

        // Ambil varian produk
        $variants = $this->variantModel->where('product_id', $product['id'])
            ->where('is_active', 1)
            ->findAll();

        $product['price']    = (int)$product['price'];
        $product['images']   = $images;
        $product['variants'] = $variants;

        return $this->respondWithSuccess($product, 'Detail produk berhasil dimuat.');
    }
}
