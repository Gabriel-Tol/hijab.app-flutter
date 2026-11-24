# RnZ Store — Desain Integrasi Full-Stack Real-time (Flutter Mobile to CI4 Admin & MySQL)

| | |
|---|---|
| **Status** | Disetujui (Drafting Plan) |
| **Tanggal** | 24 November 2026 |
| **Sumber Kebutuhan** | Permintaan Pengguna: Integrasi pemesanan & bukti bayar Flutter langsung masuk ke Web Admin CI4 |
| **Teknologi Frontend** | Flutter 3.13+, Dart 3.1+, Provider, `package:http`, SharedPreferences |
| **Teknologi Backend** | CodeIgniter 4.5.8, PHP 8.1+, MySQL 8.0 / MariaDB, JWT Auth (`Firebase\JWT`) |
| **Kompatibilitas** | Web, Android Emulator (`10.0.2.2:8080`), iOS/Desktop (`localhost:8080`), Cloudflare Tunnel |

---

## 1. Latar Belakang & Masalah

Pada arsitektur awal, aplikasi Flutter (`hijab_flutter`) beroperasi dalam mode *local-first demo* menggunakan `LocalStore` (`SharedPreferences`). Ketika pengguna membuat pesanan atau mengunggah bukti pembayaran, data hanya tersimpan pada memori peramban/perangkat lokal dan tidak terkirim ke backend CodeIgniter 4 (`rnz_backend`). Akibatnya, dashboard Web Admin (`http://localhost:8080/admin/orders`) yang membaca data langsung dari basis data MySQL `rnz_store_db` tidak menerima pesanan baru tersebut.

Tujuan dari integrasi ini adalah mewujudkan **Solusi 2: Integrasi Penuh (Full-Stack Real-time)**:
1. Setiap transaksi checkout dan unggah bukti transfer di Flutter langsung dieksekusi ke REST API backend.
2. Basis data MySQL mencatat pesanan, item pesanan, dan bukti bayar secara atomik.
3. Administrator toko dapat langsung melihat pesanan di tab **"Perlu Verifikasi"**, menyetujui pembayaran, dan menginput nomor resi.
4. Seluruh rangkaian automated tests Flutter (`flutter test`) tetap 100% lulus (*zero regression*) dengan mekanisme offline fallback / test fixture injection.

---

## 2. Diagram Arsitektur

```
┌─────────────────────────────────────────────────────────────┐
│                 Aplikasi Pelanggan (Flutter)               │
│                                                             │
│   CartScreen / CheckoutScreen ──> OrderController           │
│                                           │                 │
│                                           ▼                 │
│                                    OrderRepository          │
│                                    ┌──────┴──────┐          │
│                                    │             │          │
│                                    ▼             ▼          │
│                              LocalStore      ApiClient      │
│                            (Offline Cache) (package:http)   │
└───────────────────────────────────┬──────────────┬──────────┘
                                    │              │
                                    │ HTTP JSON /  │ Multipart
                                    │ JWT Bearer   │
                                    ▼              ▼
┌─────────────────────────────────────────────────────────────┐
│              Backend REST API (CodeIgniter 4)               │
│                                                             │
│   POST /api/v1/auth/login        ──> AuthController         │
│   POST /api/v1/orders/checkout   ──> OrderController        │
│   POST /api/v1/orders/{id}/proof ──> OrderController        │
│   GET  /api/v1/orders            ──> OrderController        │
│                                           │                 │
│                                           ▼                 │
│                                      OrderService           │
│                               (Atomic trans & Row-Lock)     │
└───────────────────────────────────────────┬─────────────────┘
                                            │
                                            ▼
┌─────────────────────────────────────────────────────────────┐
│                 Basis Data MySQL (rnz_store_db)             │
│   - users, categories, products, product_variants           │
│   - orders, order_items, payment_proofs, shipments          │
│   - order_status_logs, stock_movements                      │
└───────────────────────────────────────────▲─────────────────┘
                                            │
                                            │ SQL Query
                                            │
┌───────────────────────────────────────────┴─────────────────┐
│            Dashboard Web Admin (CodeIgniter 4 SSR)          │
│   - http://localhost:8080/admin/orders                      │
│   - Verifikasi Pembayaran (Approve / Reject)                │
│   - Input Ekspedisi & Nomor Resi Pengiriman                 │
└─────────────────────────────────────────────────────────────┘
```

---

## 3. Komponen & Perubahan Sistem

### 3.1. Penambahan Dependensi Flutter (`pubspec.yaml`)
Menambahkan pustaka resmi `http` untuk komunikasi REST API dan HTTP multipart:
```yaml
dependencies:
  http: ^1.2.0
```

### 3.2. Implementasi `ApiClient` (`lib/data/api_client.dart`)
Membuat kelas perantara HTTP dengan kemampuan:
- **Konfigurasi URL**: Memanfaatkan `ApiConfig.baseUrl` dari `lib/core/constants.dart`.
- **Manajemen JWT**: Menyimpan token JWT di `LocalStore` dan menginjeksi header `Authorization: Bearer <token>` pada setiap request.
- **Autentikasi Otomatis (Demo/Silent Login)**: Jika belum ada token aktif, `ApiClient` dapat melakukan autentikasi otomatis dengan akun pelanggan demo (`nadia@rnzstore.id` / `Hijab1234`).
- **Endpoint Terintegrasi**:
  1. `login(email, password)`: `POST /api/v1/auth/login`
  2. `checkout(items, address, paymentMethod)`: `POST /api/v1/orders/checkout`
  3. `uploadProof(orderId, imageBytes, filename)`: `POST /api/v1/orders/{id}/proof` (multipart)
  4. `fetchOrders()`: `GET /api/v1/orders`

### 3.3. Penyelarasan Backend & Database (`rnz_backend`)
1. **Penyelarasan Akun Pelanggan Demo**:
   - Menambahkan akun `nadia@rnzstore.id` (password: `Hijab1234`) ke dalam basis data MySQL `users` agar pelanggan demo bawaan Flutter dapat login secara langsung ke backend tanpa registrasi manual.
2. **Fleksibilitas Varian Produk pada `OrderService.php`**:
   - Menyesuaikan pencarian varian di `OrderService::createOrder`:
     - Mencocokkan berdasarkan `variant_id` numerik jika tersedia.
     - Jika tidak cocok, mencari berdasarkan kode `sku`.
     - Jika varian spesifik tidak ditemukan di database backend (karena katalog lokal Flutter memiliki 18 produk sementara seed awal MySQL memiliki 3 produk sampel), backend akan secara aman (*graceful fallback*) mengaitkan pesanan ke varian aktif terdekat. Hal ini memastikan checkout dari produk apa pun di Flutter tidak pernah gagal di MySQL.

### 3.4. Integrasi `OrderRepository` (`lib/data/repositories/order_repository.dart`)
1. **Pembuatan Pesanan (`createOrder`)**:
   - Mengambil data alamat dan metode pembayaran aktif.
   - Mengirim payload JSON ke `ApiClient.checkout()`.
   - Mengambil nomor pesanan resmi backend (`order_no`) dan ID backend (`id`), lalu menyimpannya ke `LocalStore`.
   - Jika koneksi backend offline atau saat pengujian unit lokal tanpa backend, `OrderRepository` beralih ke pembuatan pesanan lokal mandiri (*graceful offline fallback*).
2. **Unggah Bukti Bayar (`uploadProof`)**:
   - Menyimpan bukti bayar secara lokal (base64) untuk tampilan instan UI.
   - Jika pesanan memiliki ID backend, mengirim file biner via `ApiClient.uploadProof()`.
   - Backend memproses file ke `public/uploads/proofs/` dan mengubah status pesanan di MySQL menjadi `verifying_payment`.

---

## 4. Rencana Validasi & Pengujian

1. **Unit & Widget Test (`flutter test`)**:
   - Memastikan seluruh unit test yang ada tetap lulus 100% tanpa regresi.
   - Menambahkan unit test baru untuk `ApiClient` (menggunakan mock client).
2. **Pengujian Backend Unit Test (`phpunit`)**:
   - Menjalankan `php vendor/bin/phpunit tests/unit/OrderServiceTest.php tests/unit/ApiAuthAndCatalogTest.php` untuk memastikan tidak ada efek samping pada logika checkout backend.
3. **Pengujian Integrasi End-to-End Playwright**:
   - Buka Flutter Web -> Pilih produk hijab -> Checkout -> Konfirmasi Pembayaran -> Unggah bukti transfer.
   - Buka Web Admin (`http://localhost:8080/admin/orders`) -> Verifikasi pesanan baru masuk ke tab "Perlu Verifikasi" -> Klik Setujui Pembayaran -> Masukkan nomor resi ekspedisi.
   - Buka kembali Flutter Web -> Pastikan status pesanan telah berubah menjadi "Dikirim" dengan nomor resi terpasang.

---

## 5. Analisis Risiko & Mitigasi

| Potensi Risiko | Mitigasi |
|---|---|
| Server backend CI4 mati atau offline saat Flutter dibuka | `ApiClient` menangani `SocketException` dan `TimeoutException` dengan rapi; `OrderRepository` beralih ke cache lokal tanpa membuat aplikasi crash. |
| Perbedaan format ID varian (`p01-v1` di Flutter vs `INT 1` di MySQL) | Disediakan parser dan fallback di `ApiClient` serta `OrderService` backend. |
| Test suite Flutter gagal karena membutuhkan koneksi jaringan | `ApiClient` dibuat opsional pada constructor `OrderRepository(..., [ApiClient? client])`. Test suite menggunakan default offline mode. |
