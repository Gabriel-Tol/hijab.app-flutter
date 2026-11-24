<?php

namespace App\Database\Seeds;

use CodeIgniter\Database\Seeder;

class RnzStoreSeeder extends Seeder
{
    public function run()
    {
        $now = date('Y-m-d H:i:s');

        // 1. Users
        $users = [
            [
                'name'          => 'Rafly Ikhsanida (Admin)',
                'email'         => 'admin@rnzstore.com',
                'phone'         => '081200000001',
                'password_hash' => password_hash('AdminRnZ2026!', PASSWORD_BCRYPT),
                'role'          => 'admin',
                'status'        => 'active',
                'created_at'    => $now,
                'updated_at'    => $now,
            ],
            [
                'name'          => 'Nadia Putri',
                'email'         => 'pelanggan@rnzstore.com',
                'phone'         => '081234567890',
                'password_hash' => password_hash('Nadia1234!', PASSWORD_BCRYPT),
                'role'          => 'customer',
                'status'        => 'active',
                'created_at'    => $now,
                'updated_at'    => $now,
            ],
        ];
        $this->db->table('users')->insertBatch($users);
        $customerId = $this->db->table('users')->where('email', 'pelanggan@rnzstore.com')->get()->getRow()->id;

        // 2. Customer Address
        $this->db->table('addresses')->insert([
            'user_id'         => $customerId,
            'label'           => 'Rumah',
            'recipient_name'  => 'Nadia Putri',
            'recipient_phone' => '081234567890',
            'province'        => 'Kalimantan Barat',
            'city'            => 'Kota Pontianak',
            'district'        => 'Pontianak Kota',
            'address_line'    => 'Jl. Gajah Mada No. 45',
            'postal_code'     => '78121',
            'is_default'      => 1,
            'created_at'      => $now,
            'updated_at'      => $now,
        ]);

        // 3. Categories
        $categories = [
            ['name' => 'Hijab Segiempat', 'slug' => 'hijab-segiempat', 'is_active' => 1, 'created_at' => $now, 'updated_at' => $now],
            ['name' => 'Pashmina', 'slug' => 'pashmina', 'is_active' => 1, 'created_at' => $now, 'updated_at' => $now],
            ['name' => 'Dalaman', 'slug' => 'dalaman', 'is_active' => 1, 'created_at' => $now, 'updated_at' => $now],
            ['name' => 'Gamis & Set Koko', 'slug' => 'gamis-set-koko', 'is_active' => 1, 'created_at' => $now, 'updated_at' => $now],
        ];
        $this->db->table('categories')->insertBatch($categories);

        $catSegiempat = $this->db->table('categories')->where('slug', 'hijab-segiempat')->get()->getRow()->id;
        $catPashmina  = $this->db->table('categories')->where('slug', 'pashmina')->get()->getRow()->id;
        $catDalaman   = $this->db->table('categories')->where('slug', 'dalaman')->get()->getRow()->id;

        // 4. Products & Variants
        // Product 1
        $this->db->table('products')->insert([
            'category_id' => $catPashmina,
            'name'        => 'Pashmina Ceruty Baby Doll',
            'slug'        => 'pashmina-ceruty-baby-doll',
            'description' => 'Pashmina bahan ceruty baby doll premium, jatuh, tidak licin, dan mudah dibentuk.',
            'price'       => 65000,
            'is_active'   => 1,
            'created_at'  => $now,
            'updated_at'  => $now,
        ]);
        $prod1Id = $this->db->insertID();

        $this->db->table('product_variants')->insertBatch([
            ['product_id' => $prod1Id, 'color' => 'Dusty Pink', 'size' => '175x75 cm', 'sku' => 'PASH-CER-DP', 'stock' => 15, 'is_active' => 1, 'created_at' => $now, 'updated_at' => $now],
            ['product_id' => $prod1Id, 'color' => 'Mocca', 'size' => '175x75 cm', 'sku' => 'PASH-CER-MC', 'stock' => 12, 'is_active' => 1, 'created_at' => $now, 'updated_at' => $now],
            ['product_id' => $prod1Id, 'color' => 'Hitam', 'size' => '175x75 cm', 'sku' => 'PASH-CER-HT', 'stock' => 20, 'is_active' => 1, 'created_at' => $now, 'updated_at' => $now],
        ]);

        // Product 2
        $this->db->table('products')->insert([
            'category_id' => $catSegiempat,
            'name'        => 'Hijab Segiempat Voal Premium',
            'slug'        => 'hijab-segiempat-voal-premium',
            'description' => 'Segiempat voal berkualitas tinggi, tegak di dahi, adem, dan serat rapat.',
            'price'       => 45000,
            'is_active'   => 1,
            'created_at'  => $now,
            'updated_at'  => $now,
        ]);
        $prod2Id = $this->db->insertID();

        $this->db->table('product_variants')->insertBatch([
            ['product_id' => $prod2Id, 'color' => 'Navy', 'size' => '115x115 cm', 'sku' => 'VOAL-PREM-NV', 'stock' => 10, 'is_active' => 1, 'created_at' => $now, 'updated_at' => $now],
            ['product_id' => $prod2Id, 'color' => 'Maroon', 'size' => '115x115 cm', 'sku' => 'VOAL-PREM-MR', 'stock' => 8, 'is_active' => 1, 'created_at' => $now, 'updated_at' => $now],
            ['product_id' => $prod2Id, 'color' => 'Sage Green', 'size' => '115x115 cm', 'sku' => 'VOAL-PREM-SG', 'stock' => 14, 'is_active' => 1, 'created_at' => $now, 'updated_at' => $now],
        ]);

        // Product 3
        $this->db->table('products')->insert([
            'category_id' => $catDalaman,
            'name'        => 'Inner Ciput Ninja Anti Pusing',
            'slug'        => 'inner-ciput-ninja-anti-pusing',
            'description' => 'Ciput ninja berbahan kaos rayon premium, elastis dan adem dipakai seharian.',
            'price'       => 25000,
            'is_active'   => 1,
            'created_at'  => $now,
            'updated_at'  => $now,
        ]);
        $prod3Id = $this->db->insertID();

        $this->db->table('product_variants')->insertBatch([
            ['product_id' => $prod3Id, 'color' => 'Hitam', 'size' => 'All Size', 'sku' => 'CIPUT-NNJ-HT', 'stock' => 30, 'is_active' => 1, 'created_at' => $now, 'updated_at' => $now],
            ['product_id' => $prod3Id, 'color' => 'Nude', 'size' => 'All Size', 'sku' => 'CIPUT-NNJ-ND', 'stock' => 25, 'is_active' => 1, 'created_at' => $now, 'updated_at' => $now],
        ]);

        // 5. Payment Methods
        $paymentMethods = [
            ['type' => 'bank', 'provider' => 'Bank BCA', 'account_no' => '8930123456', 'account_name' => 'RnZ Store - Rafly', 'is_active' => 1, 'created_at' => $now, 'updated_at' => $now],
            ['type' => 'bank', 'provider' => 'Bank Mandiri', 'account_no' => '1460012345678', 'account_name' => 'RnZ Store - Rafly', 'is_active' => 1, 'created_at' => $now, 'updated_at' => $now],
            ['type' => 'ewallet', 'provider' => 'GoPay', 'account_no' => '081298765432', 'account_name' => 'RnZ Store', 'is_active' => 1, 'created_at' => $now, 'updated_at' => $now],
            ['type' => 'ewallet', 'provider' => 'Dana', 'account_no' => '081298765432', 'account_name' => 'RnZ Store', 'is_active' => 1, 'created_at' => $now, 'updated_at' => $now],
        ];
        $this->db->table('payment_methods')->insertBatch($paymentMethods);

        // 6. Shipping Rates
        $shippingRates = [
            ['region_name' => 'Kota Pontianak (Flat)', 'cost' => 10000, 'is_active' => 1, 'created_at' => $now, 'updated_at' => $now],
            ['region_name' => 'Kubu Raya', 'cost' => 15000, 'is_active' => 1, 'created_at' => $now, 'updated_at' => $now],
            ['region_name' => 'Kalbar (Luar Kota)', 'cost' => 25000, 'is_active' => 1, 'created_at' => $now, 'updated_at' => $now],
            ['region_name' => 'Luar Pulau Kalimantan', 'cost' => 45000, 'is_active' => 1, 'created_at' => $now, 'updated_at' => $now],
        ];
        $this->db->table('shipping_rates')->insertBatch($shippingRates);
    }
}
