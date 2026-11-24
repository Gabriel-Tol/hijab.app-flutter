# RnZ Store — Backend CodeIgniter 4 & Web Admin Dashboard Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Membangun subsistem backend REST API (`/api/v1`) dan web admin dashboard berbasis CodeIgniter 4, MySQL (Laragon), dan Bootstrap 5, serta menyediakan akses publik online gratis via Cloudflare Tunnel/Ngrok untuk dihubungkan ke aplikasi mobile Flutter RnZ Store.

**Architecture:** CodeIgniter 4 berjalan di Laragon lokal melayani dua pintu: Web Admin responsif berbasis sesi & CSRF (Bootstrap 5) dan REST API tanpa status (JWT) untuk aplikasi mobile Flutter. Aturan bisnis (validasi stok atomik dengan row lock, transisi pesanan, audit log stok) berada pada shared model/service layer. Laragon diekspos ke domain HTTPS publik gratis menggunakan Cloudflare Tunnel atau Ngrok.

**Tech Stack:** PHP 8.1+, CodeIgniter 4.5+, MySQL 8.0/MariaDB (Laragon), Bootstrap 5, DomPDF, Firebase JWT (`firebase/php-jwt`), Cloudflare Tunnel (`cloudflared`).

**Spec:** `docs/superpowers/specs/2026-11-24-rnz-store-ci4-admin-backend-design.md`

## Global Constraints

- **PHP Version:** PHP 8.1 atau 8.2 dengan ekstensi `intl`, `mbstring`, `gd`, `mysqli`, `curl` aktif.
- **Database Engine:** MySQL / MariaDB dengan engine **InnoDB** dan charset `utf8mb4_unicode_ci`.
- **Mata Uang & Angka:** Seluruh nilai rupiah disimpan sebagai integer bulat tanpa desimal (mis. `85000`).
- **Format Nomor Pesanan:** Format wajib `RNZ-YYMMDD-NNNN` (mis. `RNZ-261124-0001`).
- **Batas Waktu Pembayaran:** Persis 24 jam sejak pesanan dibuat (`created_at + 24 hours`).
- **Penyimpanan Gambar:** Foto produk di `public/uploads/products/` (maks. 2 MB/file, jpg/png/webp) dan bukti transfer di `public/uploads/proofs/`.
- **Format Respons API:** Format JSON sukses `{"status": 200, "data": ..., "message": "..."}` dan error `{"status": ..., "error": {"code": "...", "message": "...", "fields": {...}}}`.

## Review Focus

- Concurrency checkout race condition: dua pelanggan memesan sisa 1 unit varian pada detik yang sama — tepat 1 berhasil, transaksi kedua gagal dengan error stok tidak mencukupi, tidak terjadi stok minus.
- Transisi status ilegal: admin atau API mencoba mengubah status pesanan dari `waiting_payment` langsung ke `shipped` tanpa bukti bayar — sistem menolak dengan HTTP 422 dan mencatat log.
- Penolakan bukti transfer: admin menolak bukti bayar tanpa menyertakan alasan — validasi form menolak; bila ada alasan, status kembali ke `waiting_payment` dan alasan tersimpan untuk dilihat pelanggan.
- Keamanan otorisasi bukti bayar: akun ber-role `customer` tidak boleh mengakses panel `/admin/*` — filter me-redirect ke login dengan pesan akses ditolak.
- Pembatalan pesanan mengembalikan kuota: pesanan yang dibatalkan mengembalikan stok varian sesuai qty item dan mencatat baris mutasi `type = 'cancel'` di tabel `stock_movements`.

---

### Task 1: Setup Proyek CodeIgniter 4 & Konfigurasi Lingkungan di Laragon

**Files:**
- Create: `rnz_backend/composer.json`
- Create: `rnz_backend/.env`
- Create: `rnz_backend/app/Config/App.php`
- Create: `rnz_backend/app/Config/Database.php`
- Create: `rnz_backend/public/uploads/products/.gitkeep`
- Create: `rnz_backend/public/uploads/proofs/.gitkeep`

**Interfaces:**
- Produces: Proyek CodeIgniter 4 siap pakai terhubung ke database MySQL `rnz_store_db` di Laragon port 8080.

- [ ] **Step 1: Inisialisasi proyek CodeIgniter 4**
Jalankan composer create-project atau inisialisasi skeleton CI4 versi 4.5+ di direktori `rnz_backend/`:
```bash
composer create-project codeigniter4/appstarter rnz_backend
```

- [ ] **Step 2: Install dependensi pendukung (JWT & DomPDF)**
Masuk ke direktori `rnz_backend/` dan pasang pustaka:
```bash
cd rnz_backend && composer require firebase/php-jwt dompdf/dompdf
```

- [ ] **Step 3: Konfigurasi file `.env`**
Salin `env` menjadi `.env`, aktifkan environment `development`, atur `app.baseURL = 'http://localhost:8080/'`, buat key enkripsi `app.key`, atur koneksi MySQL Laragon (`database.default.hostname = localhost`, `database.default.database = rnz_store_db`, `database.default.username = root`, `database.default.password = ''`, `database.default.DBDriver = MySQLi`), dan tambahkan `JWT_SECRET = 'rnz_store_secret_jwt_key_2026'`.

- [ ] **Step 4: Buat direktori upload publik**
Buat folder `public/uploads/products` dan `public/uploads/proofs` serta pastikan direktori `writable/` memiliki hak akses tulis.

- [ ] **Step 5: Uji server lokal CI4**
Jalankan: `php spark serve --port=8080` dan periksa `curl -I http://localhost:8080`
Expected: HTTP 200 OK dengan halaman sambutan CodeIgniter.

- [ ] **Step 6: Commit konfigurasi awal**
```bash
git add rnz_backend/
git commit -m "feat: inisialisasi proyek CodeIgniter 4 dan konfigurasi lingkungan Laragon"
```

---

### Task 2: Migrasi Database & Seeder Awal

**Files:**
- Create: `rnz_backend/app/Database/Migrations/2026-11-24-000001_CreateUsersAndAddressesTable.php`
- Create: `rnz_backend/app/Database/Migrations/2026-11-24-000002_CreateCatalogTables.php`
- Create: `rnz_backend/app/Database/Migrations/2026-11-24-000003_CreateOrderAndTransactionTables.php`
- Create: `rnz_backend/app/Database/Migrations/2026-11-24-000004_CreateSettingsTables.php`
- Create: `rnz_backend/app/Database/Seeds/RnzStoreSeeder.php`

**Interfaces:**
- Produces: Skema tabel database `users`, `addresses`, `categories`, `products`, `product_variants`, `product_images`, `stock_movements`, `orders`, `order_items`, `payment_proofs`, `shipments`, `order_status_logs`, `payment_methods`, `shipping_rates`.
- Produces: Seeder akun admin awal (`admin@rnzstore.com` / `AdminRnZ2026!`), kategori awal, rekening bank/e-wallet, dan tarif pengiriman awal.

- [ ] **Step 1: Buat migrasi tabel pengguna & alamat**
Definisikan tabel `users` (id, name, email, phone, password_hash, role, status, deleted_at, timestamps) dan `addresses` (id, user_id FK, label, recipient_name, recipient_phone, province, city, district, address_line, postal_code, is_default, timestamps).

- [ ] **Step 2: Buat migrasi tabel katalog & inventori**
Definisikan tabel `categories` (id, name, slug, is_active), `products` (id, category_id FK, name, slug, description, price INT, is_active, deleted_at, timestamps), `product_variants` (id, product_id FK, color, size, sku, stock INT, is_active, timestamps), `product_images` (id, product_id FK, file_path, sort_order), dan `stock_movements` (id, variant_id FK, type ENUM, qty_change INT, stock_before INT, stock_after INT, reason, ref_order_id, admin_id, created_at).

- [ ] **Step 3: Buat migrasi tabel transaksi & pesanan**
Definisikan tabel `orders` (id, order_no UNIQUE, user_id FK, status ENUM, subtotal INT, shipping_cost INT, total INT, address_snapshot JSON, payment_method_snapshot JSON, pay_before DATETIME, timestamps), `order_items` (id, order_id FK, variant_id FK, product_name, variant_label, unit_price INT, qty INT, line_total INT), `payment_proofs` (id, order_id FK, file_path, status ENUM, reject_reason, reviewed_by FK, reviewed_at, created_at), `shipments` (id, order_id FK, courier, tracking_no, shipped_at, created_at), dan `order_status_logs` (id, order_id FK, from_status, to_status, note, actor_id FK, created_at).

- [ ] **Step 4: Buat migrasi tabel pengaturan toko**
Definisikan tabel `payment_methods` (id, type, provider, account_no, account_name, is_active) dan `shipping_rates` (id, region_name, cost INT, is_active).

- [ ] **Step 5: Buat seeder data awal `RnzStoreSeeder.php`**
Isi akun admin default dengan password ter-hash (`password_hash('AdminRnZ2026!', PASSWORD_BCRYPT)`), 4 kategori hijab, rekening bank BCA & Mandiri, e-wallet GoPay & Dana, serta tarif flat ongkos kirim Pontianak & sekitarnya.

- [ ] **Step 6: Jalankan migrasi dan seeder**
Jalankan:
```bash
php spark migrate:refresh && php spark db:seed RnzStoreSeeder
```
Expected: Migrations complete, Database seeded successfully.

- [ ] **Step 7: Commit database migrations & seeds**
```bash
git add rnz_backend/app/Database/
git commit -m "feat: tambahkan migrasi database dan seeder awal RnZ Store"
```

---

### Task 3: Shared Models & Service Transaksi Pesanan (Row-Locking Stok)

**Files:**
- Create: `rnz_backend/app/Models/UserModel.php`
- Create: `rnz_backend/app/Models/CategoryModel.php`
- Create: `rnz_backend/app/Models/ProductModel.php`
- Create: `rnz_backend/app/Models/VariantModel.php`
- Create: `rnz_backend/app/Models/StockMovementModel.php`
- Create: `rnz_backend/app/Models/OrderModel.php`
- Create: `rnz_backend/app/Models/OrderItemModel.php`
- Create: `rnz_backend/app/Models/PaymentProofModel.php`
- Create: `rnz_backend/app/Models/OrderStatusLogModel.php`
- Create: `rnz_backend/app/Models/PaymentMethodModel.php`
- Create: `rnz_backend/app/Models/ShippingRateModel.php`
- Create: `rnz_backend/app/Services/OrderService.php`
- Create: `rnz_backend/tests/unit/OrderServiceTest.php`

**Interfaces:**
- Produces: `OrderService::createOrder(int $userId, array $items, array $addressData, array $paymentMethodData): array`
- Produces: `OrderService::cancelOrder(int $orderId, ?string $reason, ?int $actorId): bool`
- Produces: `OrderService::adjustStock(int $variantId, int $qtyChange, string $reason, int $adminId): array`

- [ ] **Step 1: Tulis unit test untuk OrderService**
Buat skenario test di `tests/unit/OrderServiceTest.php`:
  1. Pengurangan stok berhasil dan mutasi tercatat saat order dibuat.
  2. Transaksi dibatalkan (rollback) jika stok salah satu varian tidak cukup.
  3. Pembatalan order mengembalikan stok secara akurat.

- [ ] **Step 2: Buat model-model CI4 dengan validation rules**
Buat `UserModel`, `ProductModel`, `VariantModel`, `OrderModel`, dll. lengkap dengan `$allowedFields`, `$useTimestamps = true`, dan validasi data.

- [ ] **Step 3: Implementasikan `OrderService.php`**
Implementasikan metode atomik `createOrder()` menggunakan transaksi DB `$db->transBegin()`, row locking `SELECT ... FOR UPDATE` pada tabel `product_variants`, pengurangan stok, pencatatan `stock_movements`, penyimpanan pesanan & item, dan generate kode pesanan unik `RNZ-YYMMDD-NNNN`.
Implementasikan `cancelOrder()` untuk mengembalikan stok dan mencatat status `cancelled`.
Implementasikan `adjustStock()` untuk keperluan stock opname admin.

- [ ] **Step 4: Jalankan unit test**
Jalankan: `php spark test`
Expected: Seluruh skenario pengujian transaksi dan stok PASS.

- [ ] **Step 5: Commit shared models & order service**
```bash
git add rnz_backend/app/Models/ rnz_backend/app/Services/ rnz_backend/tests/
git commit -m "feat: implementasi shared models dan OrderService dengan row-locking stok"
```

---

### Task 4: Autentikasi Web Admin & Template Layout Bootstrap 5

**Files:**
- Create: `rnz_backend/app/Filters/AdminAuthFilter.php`
- Create: `rnz_backend/app/Controllers/Admin/AuthController.php`
- Create: `rnz_backend/app/Controllers/Admin/DashboardController.php`
- Create: `rnz_backend/app/Views/admin/layouts/main.php`
- Create: `rnz_backend/app/Views/admin/layouts/sidebar.php`
- Create: `rnz_backend/app/Views/admin/layouts/navbar.php`
- Create: `rnz_backend/app/Views/admin/auth/login.php`
- Create: `rnz_backend/app/Views/admin/dashboard/index.php`

**Interfaces:**
- Consumes: `UserModel`
- Produces: Web route `/admin/login`, `/admin/logout`, `/admin/dashboard` yang dilindungi sesi `AdminAuthFilter`.

- [ ] **Step 1: Buat filter otorisasi `AdminAuthFilter.php`**
Cek apakah sesi `admin_logged_in` aktif dan `role === 'admin'`. Jika tidak, simpan pesan error flashdata dan redirect ke `/admin/login`. Daftarkan di `app/Config/Filters.php`.

- [ ] **Step 2: Buat controller `Admin\AuthController.php`**
Implementasikan `login()` (tampilkan view), `processLogin()` (validasi email/password dengan `password_verify()`, periksa role admin, set session), dan `logout()` (destroy session).

- [ ] **Step 3: Buat template layout Bootstrap 5 responsif**
Buat layout `main.php`, `sidebar.php`, dan `navbar.php` menggunakan CDN Bootstrap 5 dan Bootstrap Icons. Desain dengan tema warna modest butik (Burgundy/Cream/Slate) sesuai citra RnZ Store.

- [ ] **Step 4: Buat view login & dashboard**
Buat `login.php` dengan input email, password, token CSRF, dan kartu login elegan.
Buat `dashboard/index.php` yang menampilkan 4 kartu statistik (Omzet Bulan Ini, Pesanan Perlu Verifikasi, Pesanan Siap Kirim, Stok Tipis $\le 3$) dan tabel pesanan terbaru.

- [ ] **Step 5: Uji alur login web admin**
Buka browser ke `http://localhost:8080/admin/dashboard` -> redirect ke login.
Login dengan `admin@rnzstore.com` / `AdminRnZ2026!` -> sukses diarahkan ke Dashboard.

- [ ] **Step 6: Commit web admin auth & layout**
```bash
git add rnz_backend/app/Controllers/Admin/ rnz_backend/app/Filters/ rnz_backend/app/Views/admin/
git commit -m "feat: buat autentikasi admin dan template layout Bootstrap 5"
```

---

### Task 5: Modul Web Admin: Manajemen Produk, Kategori & Upload Galeri

**Files:**
- Create: `rnz_backend/app/Controllers/Admin/CategoryController.php`
- Create: `rnz_backend/app/Controllers/Admin/ProductController.php`
- Create: `rnz_backend/app/Views/admin/categories/index.php`
- Create: `rnz_backend/app/Views/admin/products/index.php`
- Create: `rnz_backend/app/Views/admin/products/create.php`
- Create: `rnz_backend/app/Views/admin/products/edit.php`

**Interfaces:**
- Consumes: `CategoryModel`, `ProductModel`, `VariantModel`, `ProductImageModel`
- Produces: Halaman CRUD kategori dan produk lengkap dengan upload foto dan varian dinamis.

- [ ] **Step 1: Buat CRUD Kategori `Admin\CategoryController.php`**
Implementasikan daftar kategori, tambah kategori modal, edit, dan hapus (dengan validasi cegah hapus bila kategori masih memiliki produk terkait).

- [ ] **Step 2: Buat Controller Produk `Admin\ProductController.php`**
Implementasikan:
  - `index()`: tabel produk dengan pencarian nama, filter kategori, dan status aktif.
  - `create()` & `store()`: simpan produk, tangani upload 1–5 gambar ke `public/uploads/products/`, dan loop simpan varian warna/ukuran/stok awal.
  - `edit()` & `update()`: perbarui informasi produk, kelola varian, dan tambah/hapus gambar galeri.
  - `delete()`: soft delete produk (`deleted_at`).

- [ ] **Step 3: Buat view form produk dengan varian dinamis**
Buat antarmuka JavaScript ringan pada `create.php` dan `edit.php` untuk menambah baris varian (Warna, Ukuran, Stok) secara dinamis sebelum form di-submit.

- [ ] **Step 4: Uji tambah produk dan upload foto**
Buka form tambah produk, isi nama "Pashmina Silk Premium", upload 2 foto, tambah 3 varian warna (Dusty Pink, Mocca, Sage Green) dengan masing-masing stok 10 -> Simpan.
Verifikasi: Data muncul di database dan file tersimpan di `public/uploads/products/`.

- [ ] **Step 5: Commit modul produk dan kategori admin**
```bash
git add rnz_backend/app/Controllers/Admin/ rnz_backend/app/Views/admin/categories/ rnz_backend/app/Views/admin/products/
git commit -m "feat: implementasi manajemen kategori dan produk dengan galeri foto serta varian"
```

---

### Task 6: Modul Web Admin: Verifikasi Bukti Pembayaran, Resi & Alur Pesanan

**Files:**
- Create: `rnz_backend/app/Controllers/Admin/OrderController.php`
- Create: `rnz_backend/app/Views/admin/orders/index.php`
- Create: `rnz_backend/app/Views/admin/orders/show.php`

**Interfaces:**
- Consumes: `OrderModel`, `OrderItemModel`, `PaymentProofModel`, `ShipmentModel`, `OrderStatusLogModel`
- Produces: Verifikasi bukti bayar (approve/reject), input resi ekspedisi, dan monitoring pesanan.

- [ ] **Step 1: Buat Controller Pesanan `Admin\OrderController.php`**
Implementasikan:
  - `index()`: daftar pesanan dengan tab filter (`all`, `verifying_payment`, `processing`, `shipped`, `completed`, `cancelled`).
  - `show($id)`: detail lengkap pesanan, alamat snapshot, rincian item, riwayat status log, dan bukti transfer terbaru.
  - `approvePayment($id)`: ubah status dari `verifying_payment` ke `processing`, set bukti bayar status `approved`, catat log status.
  - `rejectPayment($id)`: validasi alasan penolakan wajib terisi, ubah status bukti bayar ke `rejected`, kembalikan status pesanan ke `waiting_payment`, simpan alasan di log.
  - `submitShipment($id)`: validasi kurir dan no resi pengiriman, simpan ke tabel `shipments`, ubah status pesanan ke `shipped`.

- [ ] **Step 2: Buat tampilan detail pesanan dengan modal zoom bukti bayar**
Buat `show.php` dengan visualisasi linimasa status pesanan, pratinjau gambar bukti bayar yang dapat diklik untuk diperbesar (modal zoom), form modal penolakan bukti bayar, dan form input resi pengiriman.

- [ ] **Step 3: Uji verifikasi bukti bayar dan input resi**
Buat data dummy pesanan berstatus `verifying_payment` dengan bukti transfer.
Uji tombol Tolak dengan alasan -> status kembali `waiting_payment`.
Uji tombol Setujui -> status menjadi `processing`.
Uji input kurir "J&T" dan resi "JP1234567890" -> status menjadi `shipped`.

- [ ] **Step 4: Commit modul pesanan admin**
```bash
git add rnz_backend/app/Controllers/Admin/OrderController.php rnz_backend/app/Views/admin/orders/
git commit -m "feat: implementasi modul verifikasi pembayaran dan penginputan resi ekspedisi"
```

---

### Task 7: Modul Web Admin: Stock Opname, Pengaturan Toko & Laporan Penjualan PDF

**Files:**
- Create: `rnz_backend/app/Controllers/Admin/StockController.php`
- Create: `rnz_backend/app/Controllers/Admin/SettingController.php`
- Create: `rnz_backend/app/Controllers/Admin/ReportController.php`
- Create: `rnz_backend/app/Views/admin/stock/index.php`
- Create: `rnz_backend/app/Views/admin/settings/index.php`
- Create: `rnz_backend/app/Views/admin/reports/index.php`
- Create: `rnz_backend/app/Views/admin/reports/pdf_template.php`

**Interfaces:**
- Consumes: `VariantModel`, `StockMovementModel`, `PaymentMethodModel`, `ShippingRateModel`, `OrderModel`, `Dompdf\Dompdf`
- Produces: Stock opname audit, pengaturan toko, dan ekspor laporan penjualan PDF.

- [ ] **Step 1: Implementasikan modul stok `Admin\StockController.php`**
Buat view `stock/index.php` yang menampilkan seluruh varian dan tombol "Sesuaikan Stok". Saat form penyesuaian diisi (+/- qty dan alasan), panggil `OrderService::adjustStock()` dan tampilkan riwayat log `stock_movements`.

- [ ] **Step 2: Implementasikan modul pengaturan `Admin\SettingController.php`**
Buat antarmuka pengelolaan metode pembayaran (tambah/ubah no rekening dan e-wallet toko) dan tabel pengaturan tarif ongkos kirim flat per kota/wilayah.

- [ ] **Step 3: Implementasikan modul laporan penjualan & ekspor PDF**
Buat `Admin\ReportController.php`:
  - `index()`: filter berdasarkan tanggal mulai dan tanggal akhir, hitung total pesanan selesai/diproses dan total omzet bersih.
  - `exportPdf()`: render data laporan ke view `pdf_template.php` berformat A4 rapi, lalu stream atau unduh sebagai PDF menggunakan DomPDF.

- [ ] **Step 4: Uji ekspor laporan PDF**
Pilih rentang tanggal pada halaman laporan, tekan tombol "Cetak PDF" -> browser mengunduh berkas `Laporan_Penjualan_RnZ_Store.pdf` yang memuat tabel transaksi dan total omzet yang akurat.

- [ ] **Step 5: Commit modul stock opname, settings, dan laporan**
```bash
git add rnz_backend/app/Controllers/Admin/ rnz_backend/app/Views/admin/
git commit -m "feat: implementasi modul stok opname, pengaturan toko, dan cetak laporan penjualan PDF"
```

---

### Task 8: REST API `/api/v1` untuk Aplikasi Pelanggan Flutter

**Files:**
- Create: `rnz_backend/app/Filters/JwtAuthFilter.php`
- Create: `rnz_backend/app/Controllers/Api/V1/AuthController.php`
- Create: `rnz_backend/app/Controllers/Api/V1/CatalogController.php`
- Create: `rnz_backend/app/Controllers/Api/V1/OrderController.php`
- Create: `rnz_backend/app/Controllers/Api/V1/SettingController.php`
- Create: `rnz_backend/app/Config/Routes.php` (tambahkan grup route API)

**Interfaces:**
- Produces: Endpoint `/api/v1/auth/*`, `/api/v1/products`, `/api/v1/categories`, `/api/v1/orders`, `/api/v1/settings/*`.
- Format JSON: Standar `{status, data, message}` atau `{status, error}`.

- [ ] **Step 1: Buat `JwtAuthFilter.php`**
Baca header `Authorization: Bearer <token>`. Validasi token dengan `Firebase\JWT\JWT::decode()` menggunakan `JWT_SECRET`. Masukkan `userId` ke request pengguna. Jika gagal/kadaluwarsa, kembalikan HTTP 401 JSON.

- [ ] **Step 2: Buat Controller Auth API `Api\V1\AuthController.php`**
Implementasikan endpoint:
  - `POST /api/v1/auth/register` (registrasi akun dan alamat awal).
  - `POST /api/v1/auth/login` (login pelanggan, return JWT token 60 menit dan refresh token).
  - `POST /api/v1/auth/refresh` (tukar refresh token).

- [ ] **Step 3: Buat Controller Katalog API `Api\V1\CatalogController.php`**
Implementasikan:
  - `GET /api/v1/categories`: daftar kategori aktif.
  - `GET /api/v1/products`: daftar produk aktif dengan paginasi, filter kategori, dan pencarian teks.
  - `GET /api/v1/products/{id}`: detail produk beserta galeri gambar dan stok varian real-time.

- [ ] **Step 4: Buat Controller Pesanan API `Api\V1\OrderController.php`**
Implementasikan:
  - `POST /api/v1/orders`: checkout pesanan via `OrderService::createOrder()`.
  - `GET /api/v1/orders`: riwayat pesanan milik pelanggan yang sedang login.
  - `GET /api/v1/orders/{id}`: detail pesanan, snapshot alamat, dan informasi resi.
  - `POST /api/v1/orders/{id}/payment-proof`: upload bukti transfer (jpg/png/webp max 2MB) dan ubah status ke `verifying_payment`.
  - `POST /api/v1/orders/{id}/confirm-received`: ubah status `shipped` menjadi `completed`.

- [ ] **Step 5: Buat Controller Pengaturan API `Api\V1\SettingController.php`**
Implementasikan `GET /api/v1/settings/payment-methods` dan `GET /api/v1/settings/shipping-rates` untuk data checkout di Flutter.

- [ ] **Step 6: Uji endpoint REST API dengan curl / Postman**
Uji endpoint registrasi, login, katalog produk, dan checkout via curl.
Verifikasi: Seluruh respons menghasilkan format JSON standar sesuai spesifikasi.

- [ ] **Step 7: Commit implementasi REST API**
```bash
git add rnz_backend/app/Controllers/Api/ rnz_backend/app/Filters/ rnz_backend/app/Config/Routes.php
git commit -m "feat: selesaikan endpoint REST API v1 untuk integrasi aplikasi mobile Flutter"
```

---

### Task 9: Setup Akses Online Publik Gratis (Cloudflare Tunnel) & Integrasi Flutter

**Files:**
- Create: `rnz_backend/scripts/start-tunnel.bat`
- Create: `rnz_backend/scripts/tunnel-guide.md`
- Modify: `lib/core/constants.dart` (tambahkan URL API publik)
- Create: `rnz_backend/tests/integration/PublicApiSmokeTest.php`

**Interfaces:**
- Produces: Domain HTTPS publik gratis (mis. `https://xxxx.trycloudflare.com`) yang terhubung langsung ke Laragon port 8080.
- Produces: Pengaturan URL base API pada aplikasi mobile Flutter.

- [ ] **Step 1: Buat script otomasi Cloudflare Tunnel**
Buat `scripts/start-tunnel.bat` yang otomatis mengunduh binary portabel `cloudflared.exe` (jika belum ada) dan mengeksekusi:
```cmd
cloudflared.exe tunnel --url http://localhost:8080
```
Script ini akan mencetak URL publik `https://<random-subdomain>.trycloudflare.com` di terminal secara instan dan gratis tanpa registrasi.

- [ ] **Step 2: Dokumentasikan panduan online di `tunnel-guide.md`**
Tuliskan panduan singkat cara menjalankan Laragon + script tunnel, serta cara memasukkan URL publik tersebut ke aplikasi Flutter sebelum didemokan ke dosen.

- [ ] **Step 3: Siapkan konstanta Base URL di aplikasi Flutter**
Buka `lib/core/constants.dart` dan tambahkan konfigurasi dinamis atau flag `apiBaseUrl` agar aplikasi mobile dapat beralih antara data lokal demo dan REST API publik online.

- [ ] **Step 4: Uji konektivitas online end-to-end**
Jalankan tunnel, buka URL HTTPS publik di browser smartphone (akses `/admin/login`), dan lakukan request test API via smartphone.
Verifikasi: Web admin dan API dapat diakses dengan lancar dari luar jaringan lokal dengan sertifikat SSL/HTTPS valid.

- [ ] **Step 5: Commit script tunnel dan integrasi**
```bash
git add rnz_backend/scripts/ lib/core/constants.dart
git commit -m "feat: tambahkan script Cloudflare Tunnel online gratis dan integrasi URL pada Flutter"
```

---
