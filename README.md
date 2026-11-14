# RnZ Store — Aplikasi Mobile Pelanggan Hijab & Pashmina

Aplikasi e-commerce mobile untuk pelanggan toko hijab **RnZ Store**, dibangun menggunakan **Flutter** dengan pendekatan *local-first* (tanpa peladen backend eksternal). Semua data tersimpan aman dan terisolasi pada penyimpanan lokal perangkat menggunakan format JSON terstruktur di atas `SharedPreferences`.

Dibuat sebagai implementasi Tugas Mata Kuliah **Mobile Application Programming (Semester 5)**.

---

## Fitur Utama (User Stories US-01 — US-22)

- **Onboarding & Splash Screen**: Pengenalan nilai produk dengan navigasi transisi otomatis.
- **Autentikasi & Akun**:
  - Registrasi akun baru dengan validasi nomor telepon & email Indonesia.
  - Masuk akun dengan proteksi penguncian akun setelah 5 kali gagal percobaan.
  - Lupa kata sandi menggunakan simulasi kode OTP lokal (`123456`).
  - Hashing kata sandi berbasis SHA-256 dengan *random salt* 16-byte.
- **Katalog Produk & Pencarian**:
  - Beranda dengan banner editorial, filter kategori (Pashmina, Segi Empat, Bergo, dsb.), dan grid produk responsif.
  - Pencarian fleksibel (*case-insensitive* & pencocokan parsial).
  - Halaman detail produk dengan pemilihan warna, ukuran, informasi stok riil, dan spesifikasi bahan.
- **Keranjang Belanja**:
  - Penambahan varian dengan pemeriksaan stok atomik.
  - Pengubahan kuantitas produk dengan perlindungan batas stok minimum/maksimum.
- **Checkout & Buku Alamat**:
  - Pengelolaan buku alamat hingga 5 alamat per akun dengan pemilihan alamat utama.
  - Perhitungan ongkos kirim otomatis berdasarkan kota tujuan (tarif flat JNE/J&T/SiCepat).
  - Pembuatan pesanan atomik: pemotongan stok otomatis, snapshot harga & varian, pengosongan keranjang, dan pembuatan kode pesanan format `RNZ-YYMMDD-XXXX`.
- **Pembayaran & Siklus Pesanan**:
  - Petunjuk transfer bank lengkap dengan nomor rekening BCA simulasi dan tombol salin.
  - Unggah bukti transfer (JPEG/PNG) dengan kompresi Base64 lokal.
  - Timeline status pesanan interaktif (Menunggu Pembayaran → Verifikasi Pembayaran → Diproses → Dikirim → Selesai).
  - Nomor resi pengiriman dapat dilacak saat pesanan dalam status Dikirim.
- **Panel Mode Demo (Simulasi Admin)**:
  - Tanpa memerlukan backend CI4 atau web admin, penguji dapat menyetujui/menolak bukti transfer dan memasukkan nomor resi ekspedisi langsung dari dalam layar detail pesanan.
- **Profil, Keamanan & Privasi**:
  - Ubah profil (nama & nomor telepon).
  - Ubah kata sandi dengan verifikasi kata sandi lama.
  - Penghapusan akun permanen (anonimisasi data pengguna pada riwayat pesanan lampau).
  - Kebijakan privasi luring (penjelasan penyimpanan lokal perangkat).
  - Fitur "Reset Data Demo" untuk mengembalikan basis data ke kondisi awal kapan saja.
- **Layar Pemulihan Data (Recovery)**:
  - Proteksi terhadap korupsi data penyimpanan lokal dengan opsi pemulihan sekali klik.

---

## Kredensial Mode Demo

Untuk langsung menguji aplikasi tanpa mendaftar akun baru:

| Keterangan | Nilai |
|---|---|
| **Email Demo** | `nadia@rnzstore.id` |
| **Kata Sandi** | `Hijab1234` |
| **Kode Reset Sandi** | `123456` |
| **Rekening Transfer Demo** | BCA `8830 1234 56` a.n. RnZ Store Official |
| **WhatsApp Kontak Toko** | `+62 812-3456-7890` |

---

## Persyaratan Sistem

- **Flutter SDK**: `^3.13.4` atau lebih baru
- **Dart SDK**: `^3.1.0`
- Peramban Google Chrome (untuk web) atau Android SDK / Emulator (untuk mobile)

---

## Panduan Instalasi & Menjalankan Aplikasi

1. **Clone repositori**:
   ```bash
   git clone <repo-url>
   cd hijab_flutter
   ```

2. **Pasang dependensi**:
   ```bash
   flutter pub get
   ```

3. **Jalankan aplikasi**:
   - Menjalankan di Chrome (Web):
     ```bash
     flutter run -d chrome
     ```
   - Menjalankan di Android:
     ```bash
     flutter run
     ```

---

## Pengujian & Verifikasi Kualitas

Aplikasi ini dibangun dengan metodologi **Test-Driven Development (TDD)** dengan cakupan pengujian komprehensif (unit test model, repository, controller, router guard, hingga widget screens):

- **Menjalankan seluruh pengujian**:
  ```bash
  flutter test
  ```
  *(101 tests passed)*

- **Pemeriksaan linting dan analisis statis**:
  ```bash
  flutter analyze
  ```
  *(0 issues found)*

- **Kompilasi rilis web**:
  ```bash
  flutter build web --release
  ```

---

## Desain & Identitas Visual

Aplikasi mengusung estetika visual **Warm Editorial** yang elegan dan ramah:
- **Ivory (`#F7F2E9`)**: Latar belakang hangat menenangkan.
- **Forest Green (`#223A2D`)**: Aksen primer alami dan berwibawa.
- **Terracotta (`#C06B4E`)**: Aksen sekunder hangat untuk status penting dan penanda keranjang.
- **Ink (`#1B1A17`)**: Teks utama berbobot tinggi.
- **Muted Grey-Olive (`#5A564E`)**: Teks sekunder yang memenuhi standar aksesibilitas kontras WCAG AA (> 4.5:1).
- **Tipografi**: Judul bergaya klasik modern dengan font *Fraunces* dan keterbacaan antarmuka dengan font *Manrope*.

---

## Lisensi & Hak Cipta

Proyek ini dikembangkan khusus untuk kepentingan evaluasi akademik dan portofolio pengembangan aplikasi mobile Flutter. Seluruh materi gambar produk digunakan terbatas untuk keperluan simulasi demonstrasi.
