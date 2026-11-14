# RnZ Store — Aplikasi Pelanggan Flutter (Demo Lokal)

| | |
|---|---|
| **Status** | Disetujui; rencana implementasi dibuat |
| **Tanggal** | 14 November 2026 |
| **Sumber requirement** | `PRD_RnZ_Store_Flutter.md` |
| **Ruang lingkup** | Aplikasi pelanggan Flutter, semua story Must + Should (US-01–22) |
| **Bukan ruang lingkup** | Backend CI4, REST API, MySQL, dashboard admin web (US-23–35), payment gateway, email nyata |

## 1. Tujuan

Membangun aplikasi pelanggan RnZ Store yang dapat dijalankan dan didemokan tanpa backend, dengan seluruh alur belanja PRD: registrasi/login, profil dan alamat, katalog, pencarian/filter, keranjang, checkout, pembayaran manual dengan unggah bukti, riwayat dan pelacakan pesanan, pembatalan, konfirmasi penerimaan, dan hapus akun.

Keberhasilan demo:

1. Pengguna baru dapat mendaftar, menambah alamat, berbelanja, checkout, dan mengunggah bukti bayar tanpa error.
2. Perubahan status pesanan (termasuk simulasi admin) terlihat konsisten di riwayat, detail, dan stok.
3. Semua aturan bisnis inti (stok, total, transisi status, kedaluwarsa) memiliki unit test dan lulus.
4. `flutter analyze` tanpa temuan dan `flutter test` lulus.
5. Tampilan terasa seperti butik modest fashion, bukan template e-commerce generik.

## 2. Keputusan Teknis

| Area | Keputusan | Alasan |
|---|---|---|
| Framework | Flutter stable (3.47.x), Dart 3.13 | Sesuai PRD dan toolchain tersedia |
| Platform | Android + iOS; web hanya untuk pratinjau lokal | PRD melarang Flutter Web untuk pelanggan, tetapi web memudahkan verifikasi di mesin ini |
| State management | `provider` + `ChangeNotifier` | Paling sedikit kode, mudah dipahami tim, cukup untuk skala demo |
| Navigasi | `go_router` | Guard auth dan deep link sederhana |
| Penyimpanan | `shared_preferences` menyimpan JSON per koleksi | Tanpa native plugin tambahan; data demo kecil |
| Hash sandi | `crypto` SHA-256 + salt acak 16 byte | Lebih baik daripada plaintext; bukan pengganti Argon2 produksi |
| Gambar bukti | `image_picker`, kompresi `maxWidth/maxHeight 1600`, `imageQuality` adaptif; simpan base64 di kunci terpisah | Portabel Android/iOS/web, tidak bergantung path file |
| Format | `intl` locale `id_ID` | Rupiah dan tanggal Indonesia |
| Tautan toko | `url_launcher` ke `wa.me` | Sesuai integration point PRD |
| Font | Fraunces (judul) + Manrope (teks), dibundel | Tanpa fetch runtime; karakter editorial |
| Foto produk | Aset lokal berlisensi bebas, kredit di `assets/images/CREDITS.md` | Demo tidak bergantung internet |
| Bahasa | Indonesia, Rupiah, WIB | Non-goal multi-bahasa |

Nama paket: `rnz_store`, org `com.rnzstore`.

## 3. Arsitektur

```
lib/
  main.dart
  app.dart                      # MaterialApp.router, theme, locale
  core/
    app_theme.dart              # warna, tipografi, komponen tema
    constants.dart              # batas, durasi, daftar ekspedisi, dsb.
    formatters.dart             # Rupiah, tanggal, nomor pesanan
    validators.dart             # validasi form
    result.dart                 # Result<T> sederhana untuk operasi repository
  data/
    models/                     # User, Address, Category, Product, Variant, CartItem,
                                # Order, OrderItem, PaymentProof, Shipment, StatusLog,
                                # PaymentMethod, ShippingRate
    local_store.dart            # baca/tulis JSON ke SharedPreferences
    seed_data.dart              # data awal
    repositories/
      auth_repository.dart
      catalog_repository.dart
      cart_repository.dart
      order_repository.dart
      profile_repository.dart
  state/
    auth_controller.dart
    catalog_controller.dart
    cart_controller.dart
    order_controller.dart
  routing/
    app_router.dart
  screens/
    splash/ onboarding/ auth/ home/ catalog/ product/ cart/ checkout/
    addresses/ payment/ orders/ profile/ legal/
  widgets/                      # RnzButton, RnzTextField, ProductCard, StatusPill,
                                # QuantityStepper, EmptyState, SkeletonGrid, SectionHeader
```

### 3.1 Alur data

- Repository adalah satu-satunya akses ke `LocalStore`; controller tidak menulis JSON langsung.
- `LocalStore` memuat seluruh koleksi ke memori saat aplikasi mulai, lalu menulis koleksi yang berubah. Tidak ada akses disk di dalam `build`.
- Controller memanggil repository, memperbarui state, lalu `notifyListeners()`.
- Harga dan stok selalu dibaca ulang dari repository saat checkout; nilai dari UI tidak dipercaya.
- Error bisnis dikembalikan sebagai `Result.failure` dengan kode dan pesan Indonesia; controller menampilkannya lewat SnackBar/dialog.

### 3.2 Guard navigasi

- Publik: splash, onboarding, login, register, lupa/reset sandi, beranda, cari, detail produk, kebijakan privasi.
- Wajib login: keranjang, checkout, alamat, pesanan, profil, ubah sandi, hapus akun.
- Tamu yang menekan "Tambah ke Keranjang" diarahkan ke `/login?from=<path>`; setelah login kembali ke produk.
- Tab Pesanan/Profil untuk tamu juga mengarah ke login.
- Setelah registrasi/login sukses: ke `from` bila ada, selain itu beranda.

## 4. Penyimpanan Lokal

Kunci `SharedPreferences` (semua berprefix `rnz.v1.`):

| Kunci | Isi |
|---|---|
| `users` | daftar user (termasuk hash + salt) |
| `session` | `{ userId }`, dihapus saat logout |
| `addresses` | daftar alamat semua user |
| `categories` | daftar kategori |
| `products` | daftar produk + varian + path gambar |
| `cart` | map `userId → [{ variantId, qty }]` |
| `orders` | daftar pesanan lengkap dengan item, log, bukti, resi |
| `payment_methods` | metode pembayaran aktif/nonaktif |
| `shipping_rates` | tarif per kota |
| `login_attempts` | map email → `{ count, lockedUntil }` |
| `reset_codes` | map email → `{ codeHash, salt, expiresAt, usedAt }` |
| `onboarding_seen` | bool |
| `seed_version` | versi seed yang sudah dimuat |
| `proof.<orderId>.<proofId>` | data URL/base64 gambar bukti |

Aturan:

- Seed dijalankan saat `seed_version` kosong atau berbeda.
- Tombol "Reset Data Demo" di Profil menghapus seluruh kunci `rnz.v1.*`, memuat seed ulang, dan logout. Wajib konfirmasi.
- Jika JSON rusak, aplikasi menampilkan layar error dengan "Coba Lagi" dan opsi "Reset Data Demo"; tidak crash.
- Bukti bayar disimpan terpisah dari dokumen pesanan agar penulisan JSON utama tetap kecil.

## 5. Model Data

Semua uang bertipe `int` rupiah. Tanggal disimpan ISO 8601 dan ditampilkan WIB.

| Model | Field utama |
|---|---|
| `User` | id, name, email, phone, passwordHash, passwordSalt, role, status, deletedAt?, createdAt |
| `Address` | id, userId, label, recipientName, recipientPhone, province, city, district, addressLine, postalCode, isDefault |
| `Category` | id, name, slug, isActive |
| `Product` | id, categoryId, name, description, price, isActive, deletedAt?, images[], variants[], createdAt |
| `ProductVariant` | id, productId, color, size?, sku?, stock, isActive |
| `CartItem` | variantId, qty |
| `Order` | id, orderNo, userId, status, subtotal, shippingCost, shippingNote?, total, addressSnapshot, paymentMethodSnapshot, payBefore, createdAt, idempotencyKey, items[], proofs[], statusLogs[], shipment?, latestRejectReason?, completedAt? |
| `OrderItem` | productId, variantId, productName, variantLabel, unitPrice, qty, lineTotal, imageAsset |
| `PaymentProof` | id, storageKey, status (`pending`/`approved`/`rejected`), uploadedAt, reviewedAt?, rejectReason? |
| `Shipment` | courier, trackingNo, shippedAt |
| `StatusLog` | id, fromStatus?, toStatus, note?, actor (`customer`/`admin`/`system`), createdAt |
| `PaymentMethod` | id, type (`bank`/`ewallet`), provider, accountNo, accountName, isActive, sortOrder |
| `ShippingRate` | id, regionName, cost, isActive |
| `LoginAttempt` | email, count, lockedUntil? |
| `ResetCode` | email, codeHash, salt, expiresAt, usedAt? |

Aturan integritas:

- Email dan telepon unik (case-insensitive untuk email).
- Stok tidak boleh negatif.
- Tepat satu alamat default per user bila user memiliki alamat.
- `orderNo` unik.
- Pesanan menyimpan snapshot alamat, metode bayar, nama produk, label varian, dan harga saat dibuat.
- Menghapus akun menganonimkan `User` dan `Address`; pesanan tetap ada dengan tampilan "Pelanggan".

## 6. Seed Data

- **Akun demo:** `nadia@rnzstore.id` / `Hijab1234` (nama: Nadia Putri), dengan 2 alamat (satu default) dan 2 pesanan contoh (satu Dikirim, satu Selesai) agar riwayat langsung terlihat.
- **Kategori:** Hijab Segiempat, Pashmina, Dalaman, Gamis/Set Koko, Aksesori.
- **Produk:** ±20 produk aktif + 1 nonaktif (untuk membuktikan filter), masing-masing 1–3 gambar, harga Rp 35.000–Rp 325.000, dan 2–6 varian warna/ukuran.
- **Metode bayar:** BCA, Mandiri (bank), DANA, OVO (e-wallet) — satu nonaktif untuk membuktikan filter.
- **Ongkir:** Pontianak 15.000, Kubu Raya 18.000, Mempawah 25.000, Singkawang 30.000; kota lain tidak punya tarif (memicu "Ongkir dikonfirmasi admin").
- **Ekspedisi:** JNE, J&T, SiCepat, Pos Indonesia, Lainnya.

## 7. Spesifikasi Fungsional

### 7.1 Akun & Autentikasi

**US-01 Registrasi**
- Field: nama, email, telepon, kata sandi, konfirmasi, alamat pertama (label, penerima, telepon penerima, provinsi, kota, kecamatan, alamat lengkap, kode pos), checkbox setuju Kebijakan Privasi.
- Validasi: nama 2–100; email format valid dan unik; telepon `08xx`/`+62` 9–15 digit dan unik; sandi ≥8 dengan ≥1 huruf dan ≥1 angka; konfirmasi sama; alamat wajib.
- Pesan per field dalam bahasa Indonesia; email/telepon terdaftar punya pesan spesifik.
- Sukses: user aktif, alamat pertama menjadi default, sesi dibuat, masuk ke beranda.
- Sandi tidak pernah ditampilkan atau dicatat; hanya hash + salt yang tersimpan.

**US-02 Login & logout**
- Login email + sandi. 5 kegagalan beruntun mengunci email selama 15 menit; pesan menyebut sisa waktu.
- Sesi tetap ada setelah aplikasi ditutup sampai logout (disimpan di prefs).
- Logout menghapus sesi dan kembali ke beranda publik.
- Login berhasil mereset hitungan gagal.

**US-03 Lupa/reset sandi**
- Masukkan email; respons selalu "Jika email terdaftar, kode reset telah dibuat" (tidak membocorkan keberadaan email).
- Mode demo menampilkan dialog berisi **kode demo 6 digit** karena tidak ada SMTP; kode disimpan sebagai hash, berlaku 30 menit, sekali pakai.
- Reset memerlukan email + kode + sandi baru (aturan US-01). Kode salah/kedaluwarsa/sudah dipakai ditolak dengan pesan jelas.
- Sukses: sandi diperbarui, kode ditandai terpakai, sesi lama dihapus, pengguna diarahkan ke login.

**US-04 Profil**
- Lihat nama, email (read-only), telepon.
- Ubah nama/telepon dengan validasi sama seperti registrasi.
- Ubah sandi memerlukan sandi lama; sandi baru tidak boleh sama dengan yang lama; sukses menampilkan konfirmasi dan tetap login.
- Tautan "Hubungi Toko" membuka `wa.me` memakai nomor demo di `constants.dart` (mudah diganti nomor asli).

**US-05 Alamat**
- Maksimal 5 alamat; tepat satu default.
- Tambah/ubah/hapus; menghapus default menjadikan alamat lain default.
- Hapus alamat terakhir diperbolehkan, tetapi checkout diblokir sampai ada alamat.
- Snapshot alamat disimpan di pesanan.

**US-06 Hapus akun**
- Memerlukan konfirmasi sandi.
- Ditolak bila ada pesanan berstatus Menunggu Pembayaran, Verifikasi Pembayaran, Diproses, atau Dikirim.
- Sukses: nama/email/telepon/alamat dianonimkan, akun ditandai dihapus, sesi dihapus. Pesanan tetap ada dengan nama "Pelanggan".

### 7.2 Katalog

**US-07 Daftar produk**
- Grid 2 kolom (3–4 kolom pada lebar ≥600/900 dp), 20 produk per halaman, infinite scroll.
- Kartu: foto 3:4, nama, `Rp 85.000`, badge "Stok Habis" bila total stok 0.
- Produk nonaktif/terhapus tidak tampil.
- Skeleton saat pemuatan awal, empty state, error state + "Coba Lagi", pull-to-refresh.

**US-08 Detail produk**
- Galeri 1–5 foto, swipe, pinch/zoom (`InteractiveViewer`), indikator halaman.
- Nama, kategori, deskripsi, harga, stok total.
- Pemilih varian warna dan ukuran; varian stok 0 nonaktif.
- Stok dibaca ulang dari store saat halaman dibuka dan saat "Tambah ke Keranjang".
- Tombol nonaktif sampai varian dipilih atau bila varian habis; jumlah 1 dan tidak melebihi stok.

**US-09 Pencarian**
- Debounce 400 ms, case-insensitive, cocok sebagian kata pada nama.
- Hasil kosong: "Produk tidak ditemukan" + saran menghapus kata kunci.

**US-10 Filter kategori**
- Chip kategori aktif dapat digulir; dapat digabung dengan kata kunci.
- Tombol "Reset"; jumlah hasil tampil di atas daftar.

### 7.3 Keranjang

**US-11 Tambah**
- Menambah varian yang sama menambah qty, bukan baris baru.
- Qty awal 1; jika melebihi stok tampil "Stok tersisa N".
- Badge ikon keranjang = total qty.
- Keranjang per user (bukan per perangkat global); tamu diarahkan login.

**US-12 Ubah isi**
- Stepper −/+ dengan batas 1..stok.
- Hapus item: item hilang dari daftar, SnackBar "Urungkan" 5 detik; jika tidak diurungkan, perubahan disimpan.
- "Kosongkan keranjang" meminta konfirmasi.
- Saat memuat keranjang, qty di atas stok otomatis dipotong dan muncul peringatan.

**US-13 Total**
- Subtotal per baris dan total dihitung ulang sinkron setelah perubahan.
- Harga selalu dari produk di store, bukan dari UI.

### 7.4 Checkout & Pesanan

**US-14 Checkout**
- Memproses seluruh keranjang.
- Alamat default terpilih otomatis; pengguna dapat memilih alamat lain atau menambah alamat baru dan kembali ke checkout dengan alamat baru terpilih.
- Metode pembayaran aktif wajib dipilih; default metode aktif pertama.
- Diblokir dengan pesan bila keranjang kosong, belum ada alamat, atau belum ada metode pembayaran aktif.

**US-15 Ringkasan**
- Daftar item, varian, qty, subtotal, ongkir, total.
- Ongkir dari tarif kota; bila tidak ada, tampil "Ongkir dikonfirmasi admin" dan ongkir 0.
- Total = subtotal + ongkir, bilangan bulat.

**US-16 Membuat pesanan**
- Nomor `RNZ-YYMMDD-NNNN`, urut per hari, dijamin unik.
- Validasi stok seluruh item lebih dulu; jika ada yang kurang, tidak ada perubahan dan item yang kurang ditampilkan.
- Stok dikurangi setelah validasi, item + snapshot disimpan, keranjang dikosongkan, status Menunggu Pembayaran, `payBefore = createdAt + 24 jam`.
- Tombol dikunci saat proses; `idempotencyKey` per sesi checkout mencegah pesanan ganda.
- Layar konfirmasi menampilkan nominal, rekening/e-wallet, dan batas waktu.

### 7.5 Pembayaran & Riwayat

**US-17 Metode pembayaran**
- Hanya metode aktif; tampil jenis, provider, nomor, atas nama.
- Tombol salin nomor dengan konfirmasi SnackBar.
- Halaman pembayaran menampilkan hitung mundur sampai `payBefore`.

**US-18 Unggah bukti**
- Sumber galeri; JPG/PNG/WEBP. Validasi ekstensi dan magic bytes; file lain ditolak.
- Pra-pemeriksaan ukuran >5 MB ditolak; tipe tidak didukung ditolak.
- Kompresi sisi terpanjang ≤1600 px; target ≤1 MB (turunkan kualitas bila perlu).
- Pratinjau, progress, dan "Coba Lagi" bila gagal.
- Sukses: bukti `pending`, status → Verifikasi Pembayaran, log tercatat.
- Bila ditolak admin, alasan tampil dan pelanggan dapat mengunggah ulang.

**US-19 Riwayat & detail**
- Daftar terbaru dahulu, filter status (Semua + 6 status), pull-to-refresh.
- Detail: item, alamat snapshot, metode bayar, total, linimasa status bertimestamp, alasan penolakan.
- Data dihitung ulang saat layar dibuka/di-refresh (pengganti polling 30 detik).

**US-20 Resi**
- Setelah Dikirim: ekspedisi + nomor resi + tombol salin.
- Sebelum Dikirim bagian resi tidak tampil.

**US-21 Batal**
- Hanya pada Menunggu Pembayaran; konfirmasi; stok kembali; log.
- Auto-batal 24 jam (dicek saat aplikasi dibuka dan saat daftar/detail pesanan dimuat), alasan "Kedaluwarsa".

**US-22 Konfirmasi diterima**
- Tombol "Pesanan Diterima" pada Dikirim; mengubah ke Selesai.
- Auto-selesai 7 hari setelah `shippedAt`.

### 7.6 Panel Simulasi Admin (khusus demo)

Ditampilkan di detail pesanan dengan label "Mode Demo — aksi admin". Tidak ada di PRD sebagai fitur pelanggan; diperlukan karena dashboard admin tidak dibangun.

- Verifikasi Pembayaran → Setujui (Diproses) atau Tolak (alasan wajib, kembali Menunggu Pembayaran, batas bayar tidak diperpanjang).
- Diproses → "Input Resi" (ekspedisi dari daftar, nomor 5–30 alfanumerik) → Dikirim.
- Verifikasi Pembayaran/Diproses → Batalkan (alasan wajib) → Dibatalkan, stok kembali.
- Semua aksi tercatat di log dengan actor `admin`.

## 8. State Machine

| Dari | Ke | Pemicu | Syarat | Efek |
|---|---|---|---|---|
| — | Menunggu Pembayaran | Pelanggan membuat pesanan | Stok cukup | Stok berkurang; `payBefore` +24 jam |
| Menunggu Pembayaran | Verifikasi Pembayaran | Unggah bukti | File valid | Bukti tersimpan |
| Verifikasi Pembayaran | Diproses | Admin setuju | — | Log verifikasi |
| Verifikasi Pembayaran | Menunggu Pembayaran | Admin tolak | Alasan wajib | Alasan tampil; boleh unggah ulang |
| Diproses | Dikirim | Admin input resi | Ekspedisi + resi valid | Resi tampil |
| Dikirim | Selesai | Pelanggan konfirmasi / auto 7 hari | — | `completedAt` |
| Menunggu Pembayaran | Dibatalkan | Pelanggan batal / auto 24 jam | — | Stok kembali |
| Verifikasi Pembayaran, Diproses | Dibatalkan | Admin batal | Alasan wajib | Stok kembali |

Selesai dan Dibatalkan final. Transisi tidak valid ditolak dan tidak mengubah data. Setiap transisi menulis `StatusLog`.

## 9. Desain UI

### 9.1 Arah

Editorial hangat: butik modest fashion yang tenang, dewasa, dan mahal. Bukan ungu-gradien, bukan kartu bulat seragam, bukan ilustrasi template.

### 9.2 Token

- Warna: ivory `#F7F2E9`, permukaan `#FFFCF6`, hutan `#223A2D`, terakota `#C06B4E`, tinta `#1B1A17`, muted `#6F6A60`, garis `#E3DACB`, sukses `#3D6B4F`, bahaya `#A84532`, peringatan `#B07A2A`.
- Tipografi: Fraunces 500/600 untuk judul dan nama produk; Manrope 400/500/600 untuk body, label, harga.
- Skala teks: 12/14/16/18/22/28/36; line-height 1.4 body, 1.1 display.
- Spasi kelipatan 4; margin layar 20 dp; grid gap 12–16.
- Sudut: 4 px untuk input/kartu kecil, 12 px untuk panel, 999 px hanya untuk chip.
- Bayangan sangat halus; pemisah garis 1 px lebih sering daripada shadow.
- Ikon Material dengan ukuran 20–24; tidak memakai emoji di UI.

### 9.3 Komponen

`RnzButton` (primary hutan, outline, ghost), `RnzTextField` (label di atas, error di bawah), `ProductCard`, `CategoryChip`, `StatusPill`, `QuantityStepper`, `EmptyState`, `SkeletonGrid`, `SectionHeader`, `PriceText`, `InfoRow`, `CopyField`.

### 9.4 Layar kunci

- **Beranda:** header dengan salam + ikon keranjang berbadge; hero editorial (foto + judul serif + CTA "Lihat Koleksi"); chip kategori; "Pilihan Minggu Ini" grid; "Terbaru".
- **Detail produk:** galeri penuh dengan latar ivory, panel info naik; pemilih varian berbentuk chip; CTA lengket di bawah.
- **Keranjang:** baris editorial dengan garis pemisah, ringkasan total di panel bawah.
- **Checkout:** dua kartu (Alamat, Pembayaran) + ringkasan; CTA "Buat Pesanan".
- **Pesanan:** status pill berwarna lembut, linimasa vertikal dengan titik dan waktu.
- **Profil:** header nama + email, daftar menu bergaris, area demo terpisah.

### 9.5 Aksesibilitas & responsif

- Target ketuk ≥48 dp; kontras teks ≥4,5:1; label semantik untuk gambar produk, ikon keranjang, dan stepper.
- Mengikuti skala teks sistem; tidak ada teks terpotong pada 200%.
- Lebar konten maksimal 720 dp di web/tablet; grid menyesuaikan.
- Fokus keyboard terlihat pada web.

## 10. Penanganan Error & State

- Setiap layar data: loading, empty, error + retry; operasi tulis: tombol disabled + progress.
- Validasi form per field, pesan Indonesia, error pertama difokuskan.
- SnackBar untuk sukses/gagal ringan; dialog untuk konfirmasi destruktif.
- Offline tidak relevan karena data lokal; gambar aset selalu tersedia.
- Corrupt store: layar pemulihan, bukan crash.

## 11. Keamanan & Privasi (mode lokal)

- Sandi di-hash SHA-256 + salt; tidak pernah ditampilkan/dilog.
- Sesi disimpan di prefs (bukan secure storage) — deviasi terdokumentasi karena tidak ada token JWT nyata.
- Bukti bayar disimpan lokal, hanya dapat diakses lewat layar pesanan pemilik di perangkat ini.
- Checkbox persetujuan Kebijakan Privasi wajib saat registrasi; halaman kebijakan tersedia di Profil.
- Hapus akun menganonimkan data pribadi dan mempertahankan pesanan untuk riwayat.
- Tidak ada kunci/secret di kode.

## 12. Pengujian

### 12.1 Unit (`flutter_test`)

- Validator: nama, email, telepon, sandi, konfirmasi, alamat.
- Formatter: Rupiah, tanggal Indonesia, nomor pesanan.
- Hash & verifikasi sandi; kode reset kedaluwarsa/sudah dipakai.
- Lockout login 5×/15 menit.
- Keranjang: merge, clamp stok, subtotal/total.
- Checkout: validasi stok semua item, pengurangan stok, pengosongan keranjang, idempotensi.
- State machine: semua transisi valid dan penolakan transisi invalid.
- Auto-batal 24 jam, auto-selesai 7 hari, pengembalian stok.
- Anonimisasi akun.
- JSON round-trip semua model.

### 12.2 Widget

- Login menampilkan error validasi dan lockout.
- ProductCard menampilkan badge stok habis.
- Detail produk: tombol tambah nonaktif sampai varian dipilih; tambah sukses menaikkan badge.
- Keranjang kosong menampilkan empty state dan checkout diblokir.
- Checkout tanpa alamat menampilkan pesan blokir.
- Filter status pesanan menyaring daftar.

### 12.3 Verifikasi manual

- Jalankan di Chrome (pratinjau) dan/atau emulator Android.
- Telusuri: onboarding → registrasi → alamat → katalog → cari/filter → detail → keranjang → checkout → bayar → simulasi admin → resi → diterima → selesai → hapus akun.
- Periksa layout 360 dp, tablet, dan skala teks 200%.

### 12.4 Definition of Done

- Semua AC US-01–22 terimplementasi atau deviasi terdokumentasi.
- `flutter analyze` 0 issue; `flutter test` lulus.
- Tidak ada data contoh yang menonjol sebagai placeholder ("Lorem ipsum", nama palsu generik).
- Error/empty/loading state ada di semua layar data.
- Aset gambar/font memiliki kredit lisensi.
- README berisi cara menjalankan, akun demo, dan batasan mode lokal.

## 13. Matriks Keterlacakan

| Story | Layar/komponen | Uji utama |
|---|---|---|
| US-01 | Register | Validator, uniqueness, hash |
| US-02 | Login, Profil | Lockout, sesi |
| US-03 | Lupa/Reset | Kedaluwarsa, sekali pakai |
| US-04 | Profil, Ubah Sandi | Validasi sandi lama |
| US-05 | Alamat | Maks 5, default, snapshot |
| US-06 | Hapus Akun | Blokir pesanan aktif, anonimisasi |
| US-07 | Beranda, Cari | Paginasi, badge, state |
| US-08 | Detail Produk | Varian, stok, zoom |
| US-09 | Cari | Debounce, substring |
| US-10 | Cari | Gabungan filter, reset |
| US-11 | Detail, Keranjang | Merge, batas stok |
| US-12 | Keranjang | Stepper, undo, clamp |
| US-13 | Keranjang | Total |
| US-14 | Checkout | Blokir kosong/tanpa alamat |
| US-15 | Checkout | Ongkir, total |
| US-16 | Checkout | Nomor, stok, idempotensi |
| US-17 | Pembayaran | Salin nomor |
| US-18 | Pembayaran | Tipe, ukuran, kompresi, unggah ulang |
| US-19 | Pesanan | Filter, linimasa |
| US-20 | Detail Pesanan | Resi setelah Dikirim |
| US-21 | Detail Pesanan | Batal, stok kembali, auto-batal |
| US-22 | Detail Pesanan | Konfirmasi, auto-selesai |

## 14. Deviasi & Batasan

| PRD | Implementasi lokal | Dampak |
|---|---|---|
| REST API + JWT + refresh token | Repository lokal + sesi prefs | Tidak ada keamanan token nyata; tidak lintas perangkat |
| Email reset via SMTP | Kode demo ditampilkan di aplikasi | Bukan alur produksi |
| Verifikasi pembayaran oleh admin | Panel simulasi admin | Demo state machine, bukan otorisasi nyata |
| Dashboard admin US-23–35 | Tidak dibangun | Tidak ada CRUD produk/stok/laporan |
| Cron | Pemeriksaan saat app dibuka/refresh | Pesanan kedaluwarsa dapat tertunda sampai app dibuka |
| MySQL row lock / konkurensi | Tidak relevan (satu pengguna lokal) | Aturan stok tetap diuji unit |
| HTTPS, rate limit server, CSRF, IDOR | Tidak berlaku | Keamanan server di luar scope |
| Push notification | Tidak ada | Status terlihat saat refresh |
| iOS build | Kode lintas platform, tidak diuji di sini | Build iOS perlu Mac |

## 15. Asumsi yang Tidak Dikonfirmasi Klien

- Tarif ongkir contoh (Pontianak dan sekitarnya) hanya data demo.
- Metode bayar contoh (BCA, Mandiri, DANA, OVO) hanya data demo.
- Batas bayar 24 jam dan auto-selesai 7 hari mengikuti PRD.
- Akun demo dan pesanan contoh dibuat untuk mempercepat demo/UAT.
