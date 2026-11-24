# Panduan Menjalankan RnZ Store (Full-Stack)

Dokumen ini berisi panduan lengkap langkah demi langkah untuk menginstalasi, mengonfigurasi, dan menjalankan proyek **RnZ Store**, yang terdiri dari:
1. **Frontend Mobile / Web Client**: Aplikasi Flutter (`hijab_flutter`)
2. **Backend & Web Admin Dashboard**: CodeIgniter 4 (`rnz_backend`)
3. **Database**: MySQL (`rnz_store_db`)

---

## 1. Prasyarat Sistem (*Prerequisites*)

Pastikan perangkat Anda telah terpasang perangkat lunak berikut:

| Komponen | Versi Minimal | Keterangan |
|---|---|---|
| **PHP** | `^8.1` | Ekstensi aktif: `intl`, `mbstring`, `mysqli`, `curl`, `json` |
| **Composer** | `^2.x` | Manajemen dependensi PHP |
| **MySQL / MariaDB** | `^8.0` / `^10.4` | Tersedia via XAMPP, Laragon, atau MySQL Server standalone |
| **Flutter SDK** | `^3.13.4` (Dart `^3.1.0`) | Mendukung target Web & Android |
| **Google Chrome** | Versi terbaru | Untuk menjalankan antarmuka web Flutter |
| **Android Studio / VS Code** | Opsional | Untuk emulator Android atau perangkat fisik |

---

## 2. Menjalankan Backend CodeIgniter 4 & Web Admin

Backend menangani Web Admin (manajemen katalog, kategori, mutasi stok, verifikasi pembayaran, pencetakan resi pengiriman, ekspor PDF) serta REST API v1.

### Langkah 2.1: Buka Terminal Backend
```bash
cd rnz_backend
```

### Langkah 2.2: Buat Basis Data MySQL
Nyalakan service MySQL (misalnya melalui kontrol panel XAMPP atau Laragon), lalu buat database baru:
```sql
CREATE DATABASE rnz_store_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

### Langkah 2.3: Konfigurasi File Lingkungan (`.env`)
Pastikan file `.env` di dalam folder `rnz_backend/` sudah sesuai dengan kredensial MySQL lokal Anda:
```env
CI_ENVIRONMENT = development

app.baseURL = 'http://localhost:8080/'

database.default.hostname = localhost
database.default.database = rnz_store_db
database.default.username = root
database.default.password = ""
database.default.DBDriver = MySQLi
database.default.port = 3306
```
*(Sesuaikan `username` dan `password` jika MySQL Anda menggunakan kata sandi).*

### Langkah 2.4: Pasang Dependensi PHP (Jika Belum)
```bash
composer install
```

### Langkah 2.5: Jalankan Migrasi & Seeder Database
Perintah ini akan membuat seluruh tabel relasional dan mengisinya dengan data awal (kategori, produk, varian warna/ukuran, admin, dan pengaturan ongkir):
```bash
# Jalankan migrasi tabel
php spark migrate

# Jalankan pengisian data awal (seeder)
php spark db:seed RnzStoreSeeder
```

### Langkah 2.6: Jalankan Server Lokal Backend
```bash
php spark serve --port 8080
```
Server backend sekarang aktif di: **`http://localhost:8080`**

### Akses Web Admin Dashboard:
- **URL Login Admin**: [http://localhost:8080/admin/login](http://localhost:8080/admin/login)
- **Email**: `admin@rnzstore.com`
- **Kata Sandi**: `AdminRnZ2026!`

---

## 3. Menjalankan Aplikasi Flutter (Frontend)

Aplikasi Flutter menyediakan antarmuka pelanggan dengan dukungan *local-first storage* dan responsif di berbagai ukuran layar.

### Langkah 3.1: Buka Terminal Baru di Root Direktori
Buka jendela terminal terpisah (biarkan server backend tetap berjalan di terminal pertama):
```bash
cd hijab_flutter
```

### Langkah 3.2: Unduh Dependensi Flutter
```bash
flutter pub get
```

### Langkah 3.3: Jalankan Aplikasi

#### Opsi A: Jalankan di Google Chrome (Web) — Direkomendasikan untuk Presentasi
```bash
flutter run -d chrome
```
*Tips tampilan mobile di Chrome: Tekan `F12` (Inspect Element) -> klik ikon perangkat mobile (Ctrl+Shift+M) -> pilih preset ukuran (misal iPhone 14/15/16 Pro Max).*

#### Opsi B: Jalankan di Emulator / Perangkat Android
Pastikan emulator sudah aktif atau HP terhubung via USB Debugging (`flutter devices`):
```bash
flutter run
```

---

## 4. Kredensial Pengujian Akun Pelanggan (Mobile App)

Aplikasi mobile dilengkapi dengan akun demo siap pakai:

| Keterangan | Nilai |
|---|---|
| **Email Pelanggan Demo** | `nadia@rnzstore.id` |
| **Kata Sandi** | `Hijab1234` |
| **Kode Reset Sandi (OTP)** | `123456` |
| **Rekening Transfer Demo** | BCA `8830 1234 56` a.n. RnZ Store Official |
| **WhatsApp CS** | `+62 812-3456-7890` |

---

## 5. Menjalankan Pengujian Otomatis (*Automated Tests*)

Proyek ini telah diverifikasi 100% menggunakan automated testing.

### 1. Pengujian Flutter (Unit, Widget, & Lifecycle):
```bash
# Di direktori root (hijab_flutter)
flutter test

# Memeriksa kualitas kode & linting:
flutter analyze
```

### 2. Pengujian Backend CodeIgniter 4 (PHPUnit):
```bash
# Di direktori rnz_backend
php vendor/bin/phpunit
```

---

## 6. Pemecahan Masalah (*Troubleshooting*)

1. **Port 8080 sudah digunakan aplikasi lain**:
   Jalankan dengan port berbeda:
   ```bash
   php spark serve --port 8088
   ```
   Jangan lupa sesuaikan `app.baseURL = 'http://localhost:8088/'` di file `rnz_backend/.env`.

2. **Error `Access denied for user 'root'@'localhost'`**:
   Periksa kembali pengaturan `database.default.password` pada file `rnz_backend/.env` sesuai dengan instalasi MySQL Anda.

3. **Perubahan styling Web Admin belum terlihat**:
   Lakukan *hard refresh* pada browser dengan menekan `Ctrl + F5` atau `Ctrl + Shift + R` untuk membersihkan cache CSS browser.
