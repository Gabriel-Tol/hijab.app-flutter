<?php

namespace App\Database\Seeds;

use CodeIgniter\Database\Seeder;

class RnzStoreSeeder extends Seeder
{
    public function run()
    {
        $this->db->disableForeignKeyChecks();
        $this->db->table('shipments')->truncate();
        $this->db->table('order_status_logs')->truncate();
        $this->db->table('payment_proofs')->truncate();
        $this->db->table('order_items')->truncate();
        $this->db->table('orders')->truncate();
        $this->db->table('stock_movements')->truncate();
        $this->db->table('product_images')->truncate();
        $this->db->table('product_variants')->truncate();
        $this->db->table('products')->truncate();
        $this->db->table('categories')->truncate();
        $this->db->table('shipping_rates')->truncate();
        $this->db->table('payment_methods')->truncate();
        $this->db->table('addresses')->truncate();
        $this->db->table('users')->truncate();
        $this->db->enableForeignKeyChecks();

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
            [
                'name'          => 'Nadia Putri (Flutter Demo)',
                'email'         => 'nadia@rnzstore.id',
                'phone'         => '081234567891',
                'password_hash' => password_hash('Hijab1234', PASSWORD_BCRYPT),
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

        // 7. Demo Orders untuk Dashboard & Web Admin Testing
        $addressSnapshot = json_encode([
            'recipient_name'  => 'Nadia Putri',
            'recipient_phone' => '081234567890',
            'province'        => 'Kalimantan Barat',
            'city'            => 'Kota Pontianak',
            'district'        => 'Pontianak Kota',
            'address_line'    => 'Jl. Gajah Mada No. 45',
            'postal_code'     => '78121',
        ]);
        $paymentSnapshot = json_encode([
            'type'         => 'bank',
            'provider'     => 'Bank BCA',
            'account_no'   => '8930123456',
            'account_name' => 'RnZ Store - Rafly',
        ]);

        // Order A: Verifying Payment (Perlu Verifikasi Admin)
        $this->db->table('orders')->insert([
            'order_no'                => 'RNZ-' . date('ymd') . '-1001',
            'user_id'                 => $customerId,
            'status'                  => 'verifying_payment',
            'subtotal'                => 65000,
            'shipping_cost'           => 10000,
            'total'                   => 75000,
            'address_snapshot'        => $addressSnapshot,
            'payment_method_snapshot' => $paymentSnapshot,
            'pay_before'              => date('Y-m-d H:i:s', strtotime('+24 hours')),
            'created_at'              => date('Y-m-d H:i:s', strtotime('-2 hours')),
            'updated_at'              => date('Y-m-d H:i:s', strtotime('-1 hour')),
        ]);
        $orderAId = $this->db->insertID();

        $this->db->table('order_items')->insert([
            'order_id'      => $orderAId,
            'variant_id'    => 1,
            'product_name'  => 'Pashmina Ceruty Baby Doll',
            'variant_label' => 'Dusty Pink (175x75 cm)',
            'unit_price'    => 65000,
            'qty'           => 1,
            'line_total'    => 65000,
        ]);

        $this->db->table('payment_proofs')->insert([
            'order_id'   => $orderAId,
            'file_path'  => 'uploads/proofs/sample-proof.png',
            'status'     => 'pending',
            'created_at' => date('Y-m-d H:i:s', strtotime('-1 hour')),
        ]);

        // Order B: Processing (Siap Kirim & Input Resi)
        $this->db->table('orders')->insert([
            'order_no'                => 'RNZ-' . date('ymd') . '-1002',
            'user_id'                 => $customerId,
            'status'                  => 'processing',
            'subtotal'                => 90000,
            'shipping_cost'           => 10000,
            'total'                   => 100000,
            'address_snapshot'        => $addressSnapshot,
            'payment_method_snapshot' => $paymentSnapshot,
            'pay_before'              => date('Y-m-d H:i:s', strtotime('+12 hours')),
            'created_at'              => date('Y-m-d H:i:s', strtotime('-10 hours')),
            'updated_at'              => date('Y-m-d H:i:s', strtotime('-8 hours')),
        ]);
        $orderBId = $this->db->insertID();

        $this->db->table('order_items')->insert([
            'order_id'      => $orderBId,
            'variant_id'    => 4,
            'product_name'  => 'Hijab Segiempat Voal Premium',
            'variant_label' => 'Navy (115x115 cm)',
            'unit_price'    => 45000,
            'qty'           => 2,
            'line_total'    => 90000,
        ]);

        // Order C: Shipped (Dalam Pengiriman)
        $this->db->table('orders')->insert([
            'order_no'                => 'RNZ-' . date('ymd') . '-1003',
            'user_id'                 => $customerId,
            'status'                  => 'shipped',
            'subtotal'                => 50000,
            'shipping_cost'           => 10000,
            'total'                   => 60000,
            'address_snapshot'        => $addressSnapshot,
            'payment_method_snapshot' => $paymentSnapshot,
            'pay_before'              => date('Y-m-d H:i:s', strtotime('-1 day')),
            'created_at'              => date('Y-m-d H:i:s', strtotime('-2 days')),
            'updated_at'              => date('Y-m-d H:i:s', strtotime('-1 day')),
        ]);
        $orderCId = $this->db->insertID();

        $this->db->table('order_items')->insert([
            'order_id'      => $orderCId,
            'variant_id'    => 7,
            'product_name'  => 'Inner Ciput Ninja Anti Pusing',
            'variant_label' => 'Hitam (All Size)',
            'unit_price'    => 25000,
            'qty'           => 2,
            'line_total'    => 50000,
        ]);

        $this->db->table('shipments')->insert([
            'order_id'   => $orderCId,
            'courier'    => 'JNE',
            'tracking_no'=> 'JNE-PTK-9876543210',
            'shipped_at' => date('Y-m-d H:i:s', strtotime('-1 day')),
            'created_at' => date('Y-m-d H:i:s', strtotime('-1 day')),
        ]);
    }
}
