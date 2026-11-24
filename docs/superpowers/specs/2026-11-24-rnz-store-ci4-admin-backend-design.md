# RnZ Store — Desain Sistem Backend & Web Admin Dashboard (CodeIgniter 4 + MySQL)

| | |
|---|---|
| **Status** | Disetujui |
| **Tanggal** | 24 November 2026 |
| **Sumber Requirement** | `PRD_RnZ_Store_Flutter.md` (Epic F: US-23 s.d US-35, Bagian 4.1, 4.2, 4.4, 4.5) |
| **Teknologi Backend & Admin** | PHP 8.1+, CodeIgniter 4, MySQL 8 / MariaDB (Laragon), Bootstrap 5, DomPDF |
| **Strategi Online Gratis** | Cloudflare Tunnel / Ngrok (Domain HTTPS publik gratis dari Laragon lokal) |
| **Klien / Target Pengguna** | Pemilik Toko RnZ Store (Rafly Ikhsanida) |
| **Integrasi Klien** | Aplikasi Mobile Pelanggan (Flutter) via REST API `/api/v1` (JWT Bearer Token) |

---

## 1. Tujuan & Ruang Lingkup

Dokumen ini mendefinisikan rancangan arsitektur, basis data, dan antarmuka web untuk subsistem **Backend REST API** dan **Web Admin Dashboard** toko hijab RnZ Store.

### Ruang Lingkup (In-Scope)
1. **Web Admin Dashboard (Server-Side Rendered CI4 + Bootstrap 5):**
   - Autentikasi sesi khusus admin dengan proteksi CSRF.
   - Ringkasan statistik performa toko (omzet, pesanan masuk, peringatan stok menipis).
   - Manajemen produk, kategori, dan varian (warna, ukuran, stok) beserta upload galeri foto (1–5 foto per produk).
   - Verifikasi pembayaran manual (lihat bukti transfer, setujui pesanan, atau tolak dengan alasan).
   - Pengelolaan resi pengiriman (input kurir & nomor resi paket).
   - Penyesuaian stok manual (stock opname) dengan audit log pergerakan stok.
   - Manajemen data master: metode pembayaran (rekening bank/e-wallet) dan tarif flat ongkos kirim.
   - Pembuatan dan cetak laporan rekapitulasi penjualan per rentang tanggal dalam format PDF (DomPDF).
2. **REST API Service (`/api/v1`):**
   - Endpoint autentikasi pelanggan (JWT access & refresh token).
   - Endpoint katalog, pencarian, dan kategori untuk konsumsi Flutter.
   - Endpoint keranjang belanja dan transaksi checkout dengan validasi stok atomik (row-locking).
   - Endpoint upload bukti transfer dari aplikasi pelanggan.
   - Endpoint pelacakan riwayat dan status pesanan pelanggan.
3. **Database Relasional (MySQL / MariaDB via Laragon):**
   - Engine InnoDB untuk mendukung integritas foreign key dan transaksi atomik database (`SELECT ... FOR UPDATE`).

### Di Luar Ruang Lingkup (Non-Goals MVP)
- Payment gateway otomatis (Midtrans/Xendit) — tetap transfer manual + verifikasi admin sesuai batasan proposal.
- Integrasi pihak ketiga otomatis untuk ongkos kirim (API RajaOngkir/ekspedisi realtime).
- Multi-role admin (misal kasir vs super admin) — admin tunggal untuk pemilik toko.
- Push notification realtime berbasis Firebase Cloud Messaging (FCM) pada MVP.

---

## 2. Arsitektur Sistem

```
┌─────────────────────────────────┐
│   Aplikasi Pelanggan (Flutter)  │
│   (Android & iOS)               │
└────────────────┬────────────────┘
                 │ HTTPS / JSON
                 │ Authorization: Bearer <JWT>
                 ▼
┌──────────────────────────────────────────────────────────────┐
│             CodeIgniter 4 Backend (Laragon)                  │
│                                                              │
│  ┌─────────────────────────────┐ ┌────────────────────────┐  │
│  │   REST API (/api/v1)        │ │  Web Admin Dashboard   │  │
│  │   - Api/V1/Controllers      │ │  - Admin/Controllers   │  │
│  │   - JWT Auth Filter         │ │  - Session + CSRF      │  │
│  │   - JSON Response Formatter │ │  - Bootstrap 5 Views   │  │
│  └──────────────┬──────────────┘ └───────────┬────────────┘  │
│                 │                            │               │
│                 ▼                            ▼               │
│  ┌────────────────────────────────────────────────────────┐  │
│  │                   Shared Service & Models              │  │
│  │    (UserModel, ProductModel, OrderModel, StockModel)   │  │
│  └───────────────────────────┬────────────────────────────┘  │
└──────────────────────────────┼───────────────────────────────┘
                               │
                 ┌─────────────┴─────────────┐
                 ▼                           ▼
        ┌─────────────────┐       ┌───────────────────────┐
        │ MySQL (InnoDB)  │       │ Public Storage        │
        │ rnz_store_db    │       │ - /uploads/products/  │
        └─────────────────┘       │ - /uploads/proofs/    │
                                  └───────────────────────┘
```

### 2.1 Akses Online Publik Gratis (Cloudflare Tunnel / Ngrok)
- **Topologi Akses Online:**
  Laragon (localhost:8080) $\rightarrow$ Cloudflare Tunnel / Ngrok agent $\rightarrow$ Domain Publik HTTPS aman (misal: `https://rnz-store.trycloudflare.com`).
- **Keuntungan:**
  1. 100% gratis tanpa biaya bulanan maupun kartu kredit.
  2. Otomatis menyediakan sertifikat SSL/HTTPS yang valid (syarat mutlak Android/iOS untuk komunikasi API).
  3. Web admin dapat diakses langsung oleh penguji/dosen melalui internet, dan aplikasi Flutter di HP mahasiswa/pelanggan dapat bertransaksi langsung secara online melalui jaringan seluler.

### Struktur Folder Rekomendasi
Aplikasi web backend akan ditempatkan pada folder terpisah di samping folder aplikasi Flutter:
```text
/
├── hijab_flutter/             # Repositori aplikasi mobile Flutter
└── rnz_backend/               # Repositori backend CodeIgniter 4
    ├── app/
    │   ├── Config/            # Routes.php, Database.php, Filters.php, Jwt.php
    │   ├── Controllers/
    │   │   ├── Admin/         # Auth, Dashboard, Products, Categories, Orders, Stock, Reports, Settings
    │   │   └── Api/V1/        # Auth, Catalog, Cart, Orders, Profile
    │   ├── Filters/           # AdminAuthFilter.php, JwtAuthFilter.php
    │   ├── Helpers/           # format_helper.php (rupiah, order_code)
    │   ├── Models/            # User, Product, Variant, Image, Category, Order, OrderItem,
    │   │                      # PaymentProof, StockMovement, Shipment, Setting
    │   └── Views/
    │       └── admin/         # layouts/ (header, sidebar, footer), pages/
    ├── public/
    │   ├── assets/            # CSS, JS, Icon Bootstrap 5
    │   └── uploads/
    │       ├── products/      # Foto katalog hijab
    │       └── proofs/        # Bukti transfer pembayaran
    └── writable/
```

---

## 3. Skema Basis Data (MySQL / InnoDB)

Nama database: `rnz_store_db`  
Karakter: `utf8mb4` | Collation: `utf8mb4_unicode_ci`

### 3.1 Tabel Autentikasi & Akun
- **`users`**
  - `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY
  - `name` VARCHAR(100) NOT NULL
  - `email` VARCHAR(100) NOT NULL UNIQUE
  - `phone` VARCHAR(20) NOT NULL UNIQUE
  - `password_hash` VARCHAR(255) NOT NULL
  - `role` ENUM('customer', 'admin') DEFAULT 'customer'
  - `status` ENUM('active', 'suspended') DEFAULT 'active'
  - `created_at` DATETIME NULL
  - `updated_at` DATETIME NULL
  - `deleted_at` DATETIME NULL (soft delete untuk anonimisasi akun)

- **`addresses`**
  - `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY
  - `user_id` INT UNSIGNED NOT NULL (FK `users.id` ON DELETE CASCADE)
  - `label` VARCHAR(50) NOT NULL (contoh: Rumah, Kantor)
  - `recipient_name` VARCHAR(100) NOT NULL
  - `recipient_phone` VARCHAR(20) NOT NULL
  - `province` VARCHAR(100) NOT NULL
  - `city` VARCHAR(100) NOT NULL
  - `district` VARCHAR(100) NOT NULL
  - `address_line` TEXT NOT NULL
  - `postal_code` VARCHAR(10) NOT NULL
  - `is_default` TINYINT(1) DEFAULT 0
  - `created_at` DATETIME NULL
  - `updated_at` DATETIME NULL

### 3.2 Tabel Katalog & Inventori
- **`categories`**
  - `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY
  - `name` VARCHAR(50) NOT NULL
  - `slug` VARCHAR(60) NOT NULL UNIQUE
  - `is_active` TINYINT(1) DEFAULT 1
  - `created_at` DATETIME NULL
  - `updated_at` DATETIME NULL

- **`products`**
  - `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY
  - `category_id` INT UNSIGNED NOT NULL (FK `categories.id`)
  - `name` VARCHAR(150) NOT NULL
  - `slug` VARCHAR(160) NOT NULL UNIQUE
  - `description` TEXT NULL
  - `price` INT UNSIGNED NOT NULL (nominal rupiah bulat, misal: 85000)
  - `is_active` TINYINT(1) DEFAULT 1
  - `created_at` DATETIME NULL
  - `updated_at` DATETIME NULL
  - `deleted_at` DATETIME NULL (soft delete agar riwayat pesanan tetap valid)

- **`product_variants`**
  - `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY
  - `product_id` INT UNSIGNED NOT NULL (FK `products.id` ON DELETE CASCADE)
  - `color` VARCHAR(50) NOT NULL
  - `size` VARCHAR(30) NULL DEFAULT 'All Size'
  - `sku` VARCHAR(50) NULL UNIQUE
  - `stock` INT NOT NULL DEFAULT 0 (harus selalu >= 0)
  - `is_active` TINYINT(1) DEFAULT 1
  - `created_at` DATETIME NULL
  - `updated_at` DATETIME NULL

- **`product_images`**
  - `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY
  - `product_id` INT UNSIGNED NOT NULL (FK `products.id` ON DELETE CASCADE)
  - `file_path` VARCHAR(255) NOT NULL
  - `sort_order` TINYINT DEFAULT 1
  - `created_at` DATETIME NULL

- **`stock_movements`**
  - `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY
  - `variant_id` INT UNSIGNED NOT NULL (FK `product_variants.id`)
  - `type` ENUM('order', 'cancel', 'adjust') NOT NULL
  - `qty_change` INT NOT NULL (negatif untuk pengurangan, positif untuk penambahan)
  - `stock_before` INT NOT NULL
  - `stock_after` INT NOT NULL
  - `reason` VARCHAR(255) NOT NULL
  - `ref_order_id` INT UNSIGNED NULL (FK `orders.id` ON DELETE SET NULL)
  - `admin_id` INT UNSIGNED NULL (FK `users.id` ON DELETE SET NULL)
  - `created_at` DATETIME NULL

### 3.3 Tabel Transaksi & Pembayaran
- **`orders`**
  - `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY
  - `order_no` VARCHAR(30) NOT NULL UNIQUE (format: `RNZ-YYMMDD-NNNN`)
  - `user_id` INT UNSIGNED NOT NULL (FK `users.id`)
  - `status` ENUM('waiting_payment', 'verifying_payment', 'processing', 'shipped', 'completed', 'cancelled') DEFAULT 'waiting_payment'
  - `subtotal` INT UNSIGNED NOT NULL
  - `shipping_cost` INT UNSIGNED NOT NULL DEFAULT 0
  - `total` INT UNSIGNED NOT NULL
  - `address_snapshot` JSON NOT NULL (menyimpan salinan lengkap alamat pengiriman saat checkout)
  - `payment_method_snapshot` JSON NOT NULL (menyimpan nama bank, no rek, dan atas nama saat checkout)
  - `pay_before` DATETIME NOT NULL (waktu pembuatan + 24 jam)
  - `created_at` DATETIME NULL
  - `updated_at` DATETIME NULL

- **`order_items`**
  - `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY
  - `order_id` INT UNSIGNED NOT NULL (FK `orders.id` ON DELETE CASCADE)
  - `variant_id` INT UNSIGNED NOT NULL (FK `product_variants.id`)
  - `product_name` VARCHAR(150) NOT NULL
  - `variant_label` VARCHAR(100) NOT NULL (contoh: "Dusty Pink - All Size")
  - `unit_price` INT UNSIGNED NOT NULL
  - `qty` INT UNSIGNED NOT NULL
  - `line_total` INT UNSIGNED NOT NULL

- **`payment_proofs`**
  - `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY
  - `order_id` INT UNSIGNED NOT NULL (FK `orders.id` ON DELETE CASCADE)
  - `file_path` VARCHAR(255) NOT NULL
  - `status` ENUM('pending', 'approved', 'rejected') DEFAULT 'pending'
  - `reject_reason` TEXT NULL
  - `reviewed_by` INT UNSIGNED NULL (FK `users.id` ON DELETE SET NULL)
  - `reviewed_at` DATETIME NULL
  - `created_at` DATETIME NULL

- **`shipments`**
  - `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY
  - `order_id` INT UNSIGNED NOT NULL (FK `orders.id` ON DELETE CASCADE)
  - `courier` VARCHAR(50) NOT NULL (contoh: JNE, J&T, SiCepat)
  - `tracking_no` VARCHAR(50) NOT NULL
  - `shipped_at` DATETIME NOT NULL
  - `created_at` DATETIME NULL

- **`order_status_logs`**
  - `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY
  - `order_id` INT UNSIGNED NOT NULL (FK `orders.id` ON DELETE CASCADE)
  - `from_status` VARCHAR(30) NULL
  - `to_status` VARCHAR(30) NOT NULL
  - `note` TEXT NULL
  - `actor_id` INT UNSIGNED NULL (FK `users.id` ON DELETE SET NULL)
  - `created_at` DATETIME NULL

### 3.4 Tabel Konfigurasi Toko
- **`payment_methods`**
  - `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY
  - `type` ENUM('bank', 'ewallet') NOT NULL
  - `provider` VARCHAR(50) NOT NULL (contoh: BCA, Mandiri, GoPay)
  - `account_no` VARCHAR(50) NOT NULL
  - `account_name` VARCHAR(100) NOT NULL
  - `is_active` TINYINT(1) DEFAULT 1

- **`shipping_rates`**
  - `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY
  - `region_name` VARCHAR(100) NOT NULL (contoh: Kota Pontianak, Kubu Raya)
  - `cost` INT UNSIGNED NOT NULL
  - `is_active` TINYINT(1) DEFAULT 1

---

## 4. Alur Bisnis Transaksional & State Machine

```
                   [Pelanggan Checkout]
                            │
                            ▼
                   waiting_payment
                 (Stok dikunci & dipotong)
                  (Batas bayar 24 jam)
                     │             │
  [Unggah Bukti Bayar]             │ [Batal / Lewat 24 Jam]
                     ▼             ▼
             verifying_payment   cancelled
                     │        (Stok dikembalikan)
           ┌─────────┴─────────┐
[Admin Tolak]                  │ [Admin Setujui]
           ▼                   ▼
    waiting_payment        processing
  (Pelanggan unggah ulang)     │
                               │ [Admin Input Resi & Kurir]
                               ▼
                            shipped
                               │
                               │ [Pelanggan Konfirmasi / Otomatis 7 Hari]
                               ▼
                           completed
```

### Pencegahan Race Condition Stok (Concurrency Lock)
Pada proses checkout (`POST /api/v1/orders`), kode backend wajib membungkus operasi dalam transaksi database:
```php
$db->transBegin();
// 1. Kunci baris varian dengan FOR UPDATE
$variant = $variantModel->where('id', $variantId)->setForUpdate()->first();
if ($variant['stock'] < $qty) {
    $db->transRollback();
    return $this->fail('Stok varian tidak mencukupi');
}
// 2. Kurangi stok dan catat pergerakan
$variantModel->update($variantId, ['stock' => $variant['stock'] - $qty]);
$stockMovementModel->insert([...]);
// 3. Simpan order & order items
$orderModel->insert([...]);
$db->transCommit();
```

---

## 5. Rancangan Halaman Web Admin (CodeIgniter 4 Views)

| Modul | Endpoint URL | Fungsi & Fitur Halaman |
|---|---|---|
| **Login** | `/admin/login` | Form login admin (email, password), proteksi brute-force, dan CSRF token. |
| **Dashboard** | `/admin/dashboard` | 4 kartu ringkasan: Omzet Bulan Ini, Pesanan Masuk (Badge merah), Pesanan Diproses, Stok Tipis ($\le 3$). Tabel 5 pesanan terbaru yang perlu tindakan. |
| **Kategori** | `/admin/categories` | CRUD kategori produk hijab (nama, status aktif). Peringatan bila menghapus kategori yang masih digunakan produk. |
| **Produk** | `/admin/products` | Tabel daftar produk (filter kategori, pencarian nama), status aktif/nonaktif, soft delete. |
| **Tambah/Ubah Produk** | `/admin/products/create`, `/admin/products/{id}/edit` | Form data produk, upload 1–5 gambar (preview instan, validasi format jpg/png/webp max 2MB), dan baris dinamis varian warna/ukuran/stok. |
| **Stok & Opname** | `/admin/stock` | Tabel inventori seluruh varian produk, tombol penyesuaian manual (+/-) dengan kolom alasan wajib, serta riwayat mutasi stok. |
| **Daftar Pesanan** | `/admin/orders` | Tab filter status (`Semua`, `Menunggu Verifikasi`, `Diproses`, `Dikirim`, `Selesai`, `Dibatalkan`), pencarian no. pesanan dan nama pelanggan. |
| **Detail Pesanan** | `/admin/orders/{id}` | Ringkasan pesanan, item varian, alamat pengiriman, modal zoom bukti transfer, tombol **Setujui**, tombol **Tolak** (wajib modal alasan), dan form input resi pengiriman. |
| **Laporan Penjualan** | `/admin/reports` | Filter periode tanggal, ringkasan transaksi, tabel rincian transaksi, dan tombol **Export/Cetak PDF** via DomPDF. |
| **Pengaturan Toko** | `/admin/settings` | CRUD nomor rekening bank/e-wallet untuk pembayaran serta tabel tarif flat ongkir per wilayah. |

---

## 6. Rancangan REST API (Konsumsi Aplikasi Flutter)

Semua respons menggunakan format standar JSON:
- **Sukses:** `{"status": 200, "data": { ... }, "message": "..."}`
- **Gagal:** `{"status": 400|401|404|422|500, "error": { "code": "...", "message": "...", "fields": { ... } } }`

| Metode | Endpoint | Autentikasi | Keterangan |
|---|---|---|---|
| `POST` | `/api/v1/auth/register` | Publik | Registrasi akun pelanggan baru |
| `POST` | `/api/v1/auth/login` | Publik | Login pelanggan, mengembalikan Access Token (JWT) & Refresh Token |
| `POST` | `/api/v1/auth/refresh` | Refresh | Memperbarui Access Token |
| `GET` | `/api/v1/products` | Publik | Katalog produk (paginasi, pencarian nama, filter kategori) |
| `GET` | `/api/v1/products/{id}` | Publik | Detail produk, galeri foto, dan daftar varian beserta stok |
| `GET` | `/api/v1/categories` | Publik | Daftar kategori aktif |
| `GET` | `/api/v1/settings/payment-methods` | Publik | Daftar rekening bank & e-wallet aktif milik toko |
| `GET` | `/api/v1/settings/shipping-rates` | Publik | Daftar tarif ongkir flat |
| `POST` | `/api/v1/orders` | Bearer JWT | Membuat pesanan baru (checkout), mengunci & memotong stok atomik |
| `GET` | `/api/v1/orders` | Bearer JWT | Riwayat pesanan pelanggan yang sedang login (filter status) |
| `GET` | `/api/v1/orders/{id}` | Bearer JWT | Detail pesanan, status linimasa, info resi jika sudah dikirim |
| `POST` | `/api/v1/orders/{id}/payment-proof`| Bearer JWT | Mengunggah gambar bukti transfer |
| `POST` | `/api/v1/orders/{id}/cancel` | Bearer JWT | Membatalkan pesanan (hanya jika `waiting_payment`), stok kembali |
| `POST` | `/api/v1/orders/{id}/confirm-received`| Bearer JWT | Konfirmasi pesanan telah sampai (`shipped` -> `completed`) |

---

## 7. Strategi Pengujian & Verifikasi

1. **Pengujian Basis Data & Migrasi:**
   - Menjalankan migrasi dan seeder awal (akun admin default, kategori awal, produk sampel).
   - Memastikan constraint foreign key dan transaksi rollback berfungsi jika stok habis.
2. **Pengujian Fungsional Web Admin:**
   - Uji alur verifikasi bukti transfer: tolak bukti dengan alasan -> status berubah, setujui bukti -> status menjadi `processing`.
   - Uji input resi -> status pesanan menjadi `shipped`.
   - Uji penyesuaian stok opname manual -> tercatat di `stock_movements`.
   - Uji cetak laporan penjualan -> file PDF terunduh dan angka omzet cocok.
3. **Pengujian Integrasi REST API:**
   - Pengujian endpoint menggunakan Postman / curl (auth register, login, checkout pesanan, upload bukti bayar).
   - Pengujian verifikasi end-to-end antara Flutter dan REST API.
