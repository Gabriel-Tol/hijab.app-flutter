# Product Requirements Document (PRD)

# Aplikasi E-Commerce Mobile RnZ Store (Flutter)

| | |
|---|---|
| **Versi / Status** | 0.1 — Draft untuk review |
| **Tanggal** | 14 November 2026 |
| **Klien / Product Owner** | RnZ Store — Rafly Ikhsanida (pemilik toko) |
| **Tim Pengembang** | Fahrul Rozi, Almira Safa Aqila, Feliks Gabriel, Muhammad Ivan Abdullah |
| **Dosen Pengampu** | Mia Rosmiati — Program Studi Informatika, Universitas Bina Sarana Informatika (UBSI) Pontianak |
| **Sumber** | Proposal "Pengembangan Aplikasi E-Commerce Toko Hijab RnZ Store" |
| **Keputusan utama** | Aplikasi pelanggan dibangun dengan **Flutter** (Android & iOS), menggantikan rencana awal "berbasis web" pada proposal |

**Legenda penanda dalam dokumen ini**

- `[ASUMSI]` — keputusan sementara yang diambil penulis PRD agar dokumen utuh. Harus dikonfirmasi pemilik toko / tim.
- `[TBD]` — belum bisa diputuskan dari proposal; daftar lengkap ada di **Lampiran C**.
- `[TAMBAHAN]` — kebutuhan yang tidak tertulis eksplisit di proposal, tetapi diperlukan agar alur berfungsi atau memenuhi aturan toko aplikasi.
- Prioritas memakai MoSCoW: **Must** (wajib MVP), **Should** (diupayakan MVP), **Could** (setelah MVP).

---

## Daftar Isi

1. Executive Summary
2. User Experience & Functionality
3. AI System Requirements
4. Technical Specifications
5. Risks & Roadmap
6. Lampiran (A: Keterlacakan ke proposal · B: Selisih & isu pada proposal · C: Pertanyaan terbuka)

---

## 1. Executive Summary

### 1.1 Problem Statement

RnZ Store menjual hijab dan busana muslim lewat Instagram, WhatsApp, dan toko fisik yang tidak terhubung satu sama lain, sehingga pemilik harus mengecek stok, pesanan, pembayaran, dan rekap penjualan secara manual dan terpisah. Akibatnya stok yang tercatat tidak sinkron dengan stok nyata, rekap penjualan terlambat, riwayat transaksi sulit ditelusuri, dan pelayanan pelanggan lambat.

### 1.2 Proposed Solution

Sebuah aplikasi mobile Flutter untuk pelanggan (katalog, keranjang, checkout, unggah bukti bayar, pelacakan pesanan) yang terhubung ke backend REST API dan dashboard admin berbasis web untuk mengelola produk, stok real-time, verifikasi pembayaran, resi pengiriman, dan laporan penjualan dalam satu sistem.

### 1.3 Success Criteria (KPI)

Baseline belum pernah diukur, sehingga target berikut adalah **usulan** yang harus divalidasi pemilik toko sebelum development dimulai.

| # | KPI | Target | Cara Ukur | Waktu Ukur |
|---|---|---|---|---|
| K1 | Adopsi aplikasi | ≥ 70% pesanan online baru tercatat lewat aplikasi (sisanya masih lewat WhatsApp) | Jumlah pesanan di sistem ÷ (pesanan di sistem + pesanan manual yang dicatat pemilik) | 8 minggu setelah go-live |
| K2 | Akurasi stok | Selisih stok sistem vs stok fisik ≤ 2% dari total unit pada stock opname | Stock opname bulanan terhadap 100% varian aktif | Tiap akhir bulan, mulai bulan pertama |
| K3 | Kecepatan verifikasi pembayaran | Median waktu dari "bukti diunggah" ke "disetujui/ditolak" ≤ 6 jam | Selisih timestamp pada log status pesanan | 8 minggu setelah go-live |
| K4 | Efisiensi pelaporan | Rekap penjualan bulanan dihasilkan ≤ 1 menit (tanpa pencatatan ulang manual), selisih angka vs dashboard = 0 | Uji waktu & rekonsiliasi dengan data pesanan | Saat UAT dan tiap bulan |
| K5 | Kualitas rilis | 100% skenario UAT berprioritas Must lulus; 0 defect Critical/High terbuka saat go-live; API p95 ≤ 500 ms | Laporan UAT, bug tracker, log API | Saat go-live |

---

## 2. User Experience & Functionality

### 2.1 User Personas

| Persona | Deskripsi | Kebutuhan Utama | Perangkat |
|---|---|---|---|
| **Nadia — Pelanggan** | Perempuan 18–35 tahun, di Pontianak dan sekitarnya, terbiasa membeli hijab lewat Instagram/WhatsApp, membayar via transfer bank atau e-wallet | Melihat katalog dan stok akurat, memesan tanpa menunggu balasan chat, tahu status dan resi pesanan | Smartphone Android (dominan) dan iPhone |
| **Rafly — Admin / Pemilik Toko** | Pemilik sekaligus satu-satunya pengelola toko; mengurus stok, pesanan, pembayaran, dan pembukuan sendiri; tingkat keahlian teknis non-developer | Mengelola produk & stok dengan cepat, memverifikasi pembayaran dengan jelas, melihat omzet dan laporan tanpa rekap manual | Smartphone (memantau) dan laptop/PC (mengelola) via browser |
| **Pengunjung (belum login)** | Calon pelanggan yang baru membuka aplikasi | Menjelajah katalog sebelum memutuskan membuat akun `[ASUMSI]` | Smartphone |

### 2.2 User Stories & Acceptance Criteria

Format: `As a [pengguna], I want to [aksi] so that [manfaat]`. Setiap story diberi ID untuk keterlacakan (lihat Lampiran A).

#### Epic A — Akun & Autentikasi Pelanggan

**US-01 · Registrasi akun (Must)**
As a calon pelanggan, I want to membuat akun dengan data diri dan alamat pengiriman so that saya bisa berbelanja dan melacak pesanan.
- Field wajib: nama (2–100 karakter), email (format valid, unik), nomor WhatsApp/telepon (format Indonesia `08xx`/`+62`, 9–15 digit, unik), kata sandi (min. 8 karakter, ≥ 1 huruf dan ≥ 1 angka), dan alamat pengiriman pertama.
- Validasi muncul per field dalam bahasa Indonesia; email atau nomor yang sudah terdaftar ditolak dengan pesan spesifik.
- Setelah sukses, pengguna otomatis masuk dan diarahkan ke Beranda; kata sandi tersimpan sebagai hash, tidak pernah dikirim balik oleh API.
- Verifikasi email saat registrasi tidak termasuk MVP `[TBD]`.

**US-02 · Login & logout (Must)**
As a pelanggan, I want to masuk dan keluar dengan aman so that akun saya terlindungi.
- Login dengan email + kata sandi; sesi tetap aktif setelah aplikasi ditutup sampai token kedaluwarsa atau pengguna logout.
- 5 kali gagal beruntun mengunci login untuk akun/IP tersebut selama 15 menit.
- Logout menghapus token dari penyimpanan aman perangkat dan membatalkan refresh token di server.
- Pengunjung bisa membuka katalog tanpa login; login diwajibkan saat menambah ke keranjang atau checkout `[ASUMSI]`.

**US-03 · Reset kata sandi (Must)**
As a pelanggan, I want to mereset kata sandi yang lupa so that saya bisa masuk kembali.
- Pengguna memasukkan email; sistem mengirim tautan/kode reset yang berlaku 30 menit dan hanya bisa dipakai sekali.
- Pesan respons sama baik email terdaftar maupun tidak (mencegah penebakan email).
- Kata sandi baru memenuhi aturan US-01; seluruh sesi lama menjadi tidak valid.
- Penyedia pengiriman email (SMTP) `[TBD]`.

**US-04 · Kelola profil (Must)**
As a pelanggan, I want to melihat dan memperbarui profil so that data saya selalu benar.
- Dapat mengubah nama dan nomor telepon; email tidak dapat diubah pada MVP `[ASUMSI]`.
- Ubah kata sandi mensyaratkan kata sandi lama.
- Perubahan tersimpan dan terlihat langsung tanpa login ulang.

**US-05 · Kelola alamat pengiriman (Must)**
As a pelanggan, I want to menambah, mengubah, menghapus, dan memilih alamat utama so that checkout lebih cepat.
- Satu alamat berisi: nama penerima, telepon penerima, provinsi, kota/kabupaten, kecamatan, alamat lengkap, kode pos, dan label (mis. Rumah/Kantor).
- Maksimal 5 alamat per akun `[ASUMSI]`; tepat satu alamat bertanda utama.
- Pesanan menyimpan **salinan** alamat saat dibuat, sehingga mengubah/menghapus alamat tidak mengubah pesanan lama.

**US-06 · Hapus akun (Should) `[TAMBAHAN]`**
As a pelanggan, I want to menghapus akun saya so that data pribadi saya tidak tersimpan lagi.
- Tersedia di menu Profil; meminta konfirmasi kata sandi.
- Ditolak bila masih ada pesanan berstatus aktif (selain Selesai/Dibatalkan).
- Data pribadi (nama, email, telepon, alamat) dianonimkan; data pesanan tetap ada tanpa identitas agar laporan penjualan utuh.
- Alasan: toko aplikasi (Google Play dan Apple App Store) mewajibkan opsi hapus akun untuk aplikasi yang memiliki pendaftaran akun.

#### Epic B — Katalog Produk

**US-07 · Menjelajah daftar produk (Must)**
As a pelanggan, I want to melihat daftar produk hijab dan busana muslim so that saya bisa memilih.
- Tampilan grid 2 kolom; 20 produk per halaman dengan pemuatan bertahap (infinite scroll).
- Setiap kartu menampilkan foto, nama, harga berformat `Rp 85.000`, dan lencana "Stok Habis" bila total stok semua varian = 0.
- Produk berstatus nonaktif tidak tampil.
- Tersedia keadaan loading (skeleton), kosong, dan error dengan tombol "Coba Lagi"; pull-to-refresh memuat ulang data.

**US-08 · Melihat detail produk (Must)**
As a pelanggan, I want to melihat detail produk lengkap so that saya yakin sebelum membeli.
- Menampilkan galeri 1–5 foto (geser & zoom), nama, deskripsi, harga, pilihan varian (warna/ukuran), dan stok per varian.
- Stok diambil dari server setiap halaman dibuka dan saat menekan "Tambah ke Keranjang" (real-time sesuai proposal).
- Varian dengan stok 0 tampil nonaktif; tombol "Tambah ke Keranjang" nonaktif sampai varian dipilih.

**US-09 · Mencari produk (Must)**
As a pelanggan, I want to mencari produk berdasarkan nama so that saya cepat menemukan yang dicari.
- Pencarian tidak peka huruf besar/kecil dan cocok sebagian kata (mis. "pash" menemukan "Pashmina Viscose").
- Permintaan dikirim 400 ms setelah pengguna berhenti mengetik (debounce).
- Hasil kosong menampilkan pesan "Produk tidak ditemukan" beserta saran menghapus kata kunci.

**US-10 · Memfilter berdasarkan kategori (Must)**
As a pelanggan, I want to memfilter produk per kategori so that daftar lebih relevan.
- Kategori (mis. Hijab Segiempat, Pashmina, Dalaman, Gamis/Set Koko) berasal dari data admin dan tampil sebagai chip yang dapat digulir.
- Filter dapat dikombinasikan dengan kata kunci pencarian; ada tombol "Reset".
- Jumlah hasil tampil di atas daftar.

#### Epic C — Keranjang Belanja

**US-11 · Menambah ke keranjang (Must)**
As a pelanggan, I want to menambahkan produk, varian, dan jumlah ke keranjang so that saya bisa membeli beberapa barang sekaligus.
- Jumlah awal 1 dan tidak boleh melebihi stok varian; bila melebihi, tampil pesan "Stok tersisa N".
- Produk + varian yang sama sudah ada di keranjang → jumlahnya ditambah, bukan membuat baris baru.
- Ikon keranjang menampilkan jumlah item; keranjang disimpan di server sehingga konsisten antar perangkat.

**US-12 · Mengubah isi keranjang (Must)**
As a pelanggan, I want to mengubah jumlah, menghapus barang, atau mengosongkan keranjang so that pesanan saya sesuai.
- Tombol +/- mengubah jumlah (min. 1, maks. stok).
- Hapus item tersedia dengan opsi "Urungkan" selama 5 detik; "Kosongkan keranjang" meminta konfirmasi.
- Bila stok turun di bawah jumlah di keranjang, jumlah disesuaikan otomatis dan pengguna diberi peringatan.

**US-13 · Total belanja otomatis (Must)**
As a pelanggan, I want to melihat total belanja yang selalu terhitung so that saya tahu biaya sebelum checkout.
- Subtotal per item dan total keranjang dihitung ulang ≤ 100 ms setelah perubahan.
- Harga yang dipakai untuk pesanan selalu diambil dari server, bukan dari nilai yang dikirim aplikasi.

#### Epic D — Checkout & Pemesanan

**US-14 · Checkout dan memilih alamat (Must)**
As a pelanggan, I want to melakukan checkout dan memilih alamat pengiriman so that pesanan dikirim ke tempat yang benar.
- Checkout memproses seluruh isi keranjang (pemilihan sebagian item tidak termasuk MVP).
- Alamat utama terpilih otomatis; pengguna dapat mengganti atau menambah alamat baru tanpa meninggalkan alur checkout.
- Checkout diblokir dengan pesan jelas bila keranjang kosong atau belum ada alamat.

**US-15 · Ringkasan pesanan (Must)**
As a pelanggan, I want to melihat ringkasan pesanan sebelum membayar so that tidak ada kejutan biaya.
- Menampilkan daftar produk, varian, jumlah, subtotal, estimasi ongkir, dan total bayar.
- Estimasi ongkir diambil dari tarif wilayah yang diatur admin (US-35) `[ASUMSI]`; bila wilayah tujuan belum memiliki tarif, tampil "Ongkir dikonfirmasi admin" `[TBD]`.
- Total = subtotal + ongkir, dibulatkan dalam rupiah penuh tanpa desimal.

**US-16 · Membuat pesanan (Must)**
As a pelanggan, I want to membuat pesanan dan mendapat nomor pesanan serta instruksi bayar so that saya tahu cara menyelesaikan pembayaran.
- Nomor pesanan unik berformat `RNZ-YYMMDD-NNNN` (mis. `RNZ-261114-0007`).
- Stok varian dikurangi secara atomik saat pesanan dibuat; bila stok tidak cukup, pesanan ditolak dan item yang kurang ditunjukkan.
- Layar konfirmasi menampilkan nominal tepat, daftar rekening/e-wallet toko, dan batas waktu bayar 24 jam `[ASUMSI]`.
- Menekan tombol dua kali tidak membuat pesanan ganda (kunci idempotensi); keranjang dikosongkan setelah pesanan berhasil.

#### Epic E — Pembayaran & Riwayat

**US-17 · Memilih metode pembayaran (Must)**
As a pelanggan, I want to memilih metode transfer bank atau e-wallet so that saya membayar dengan cara yang nyaman.
- Daftar metode berasal dari data admin (nama bank/e-wallet, nomor, atas nama).
- Nomor rekening dapat disalin dengan satu ketukan.

**US-18 · Mengunggah bukti pembayaran (Must)**
As a pelanggan, I want to mengunggah bukti transfer so that pembayaran saya diverifikasi.
- Format JPG/PNG/WEBP; aplikasi mengecilkan gambar (sisi terpanjang ≤ 1600 px) sehingga ukuran akhir ≤ 1 MB; server menolak file > 5 MB atau MIME tidak sesuai.
- Ada pratinjau sebelum kirim, indikator progres, dan tombol "Coba Lagi" bila gagal.
- Setelah berhasil, status berubah menjadi **Verifikasi Pembayaran**; bila bukti ditolak admin, pelanggan dapat mengunggah ulang.

**US-19 · Riwayat dan status pesanan (Must)**
As a pelanggan, I want to melihat riwayat dan status pesanan so that saya tahu progres belanja saya.
- Daftar diurutkan terbaru dahulu, dapat difilter per status: Menunggu Pembayaran, Verifikasi Pembayaran, Diproses, Dikirim, Selesai, Dibatalkan.
- Detail pesanan memuat item, alamat, metode bayar, total, linimasa status berstempel waktu, dan alasan penolakan bukti bila ada.
- Perubahan status dari admin terlihat ≤ 30 detik setelah layar dibuka atau di-refresh (push notification tidak termasuk MVP).

**US-20 · Melihat nomor resi (Must)**
As a pelanggan, I want to melihat ekspedisi dan nomor resi so that saya bisa melacak paket.
- Nama ekspedisi dan nomor resi tampil di detail pesanan setelah status **Dikirim**, dengan tombol salin.
- Sebelum status Dikirim, bagian resi tidak ditampilkan.

**US-21 · Membatalkan pesanan (Should) `[TAMBAHAN]`**
As a pelanggan, I want to membatalkan pesanan yang belum dibayar so that saya tidak terikat pesanan yang tidak jadi.
- Pembatalan hanya tersedia pada status Menunggu Pembayaran; stok dikembalikan.
- Pesanan otomatis **Dibatalkan** bila 24 jam tanpa bukti bayar; stok dikembalikan oleh tugas terjadwal (cron).

**US-22 · Konfirmasi pesanan diterima (Should) `[TAMBAHAN]`**
As a pelanggan, I want to mengonfirmasi bahwa paket sudah sampai so that pesanan ditutup.
- Tombol "Pesanan Diterima" muncul pada status Dikirim dan mengubahnya ke **Selesai**.
- Bila tidak dikonfirmasi, pesanan otomatis Selesai 7 hari setelah status Dikirim `[ASUMSI]`.

#### Epic F — Dashboard Admin (Web)

**US-23 · Login admin (Must)**
As a admin, I want to masuk ke dashboard dengan kredensial khusus so that hanya saya yang mengelola toko.
- Halaman login terpisah dari aplikasi pelanggan; hanya akun berperan admin yang diterima.
- Sesi berakhir setelah 30 menit tidak aktif; 5 kali gagal beruntun mengunci login 15 menit; seluruh form dilindungi token CSRF.

**US-24 · Mengelola produk / CRUD (Must)**
As a admin, I want to menambah, melihat, mengubah, dan menghapus produk so that katalog selalu mutakhir.
- Field: nama, kategori, deskripsi, harga (> 0, bilangan bulat rupiah), status aktif/nonaktif.
- Produk yang pernah dipesan tidak dihapus permanen (soft delete) agar riwayat pesanan tetap utuh.
- Daftar produk admin mendukung pencarian nama dan paginasi 20 baris/halaman.

**US-25 · Mengelola kategori (Must)**
As a admin, I want to mengelola kategori produk so that katalog terorganisir.
- CRUD kategori; kategori yang masih dipakai produk tidak dapat dihapus.
- Data awal: Hijab Segiempat, Pashmina, Dalaman, Gamis/Set Koko, Aksesori `[ASUMSI]`.

**US-26 · Mengelola foto & varian produk (Must)**
As a admin, I want to mengunggah foto dan mengatur varian warna/ukuran so that pelanggan melihat pilihan yang tepat.
- 1–5 foto per produk (JPG/PNG/WEBP, ≤ 2 MB per file); server membuat thumbnail 400 px dan ukuran medium 1000 px.
- Setiap produk memiliki ≥ 1 varian (varian default "Standar" bila tidak ada pilihan); varian memuat warna, ukuran (opsional), stok, dan SKU (opsional).
- Harga ditetapkan di tingkat produk; harga berbeda per varian `[TBD]`.

**US-27 · Menyesuaikan stok (Must)**
As a admin, I want to menyesuaikan stok (stock opname) so that data stok sesuai kondisi fisik.
- Admin mengisi stok baru atau selisih (+/−) dengan alasan wajib (opname, rusak, retur, dll.).
- Setiap perubahan tercatat di riwayat stok: varian, sebelum, sesudah, alasan, admin, waktu.
- Stok tidak boleh bernilai negatif.

**US-28 · Stok diperbarui otomatis oleh transaksi (Must)**
As a admin, I want to stok berubah otomatis mengikuti pesanan so that saya tidak perlu mencatat ulang.
- Stok berkurang saat pesanan dibuat dan kembali penuh saat pesanan Dibatalkan (manual, oleh pelanggan, atau kedaluwarsa).
- Dua pelanggan memesan stok terakhir secara bersamaan → hanya satu yang berhasil, tidak terjadi stok negatif.
- Setiap perubahan otomatis tercatat di riwayat stok dengan referensi nomor pesanan.

**US-29 · Melihat pesanan masuk dan bukti bayar (Must)**
As a admin, I want to melihat daftar pesanan beserta bukti bayar so that saya dapat memeriksanya.
- Daftar dapat difilter status dan rentang tanggal serta dicari berdasarkan nomor pesanan/nama pelanggan; paginasi 20 baris.
- Menu menampilkan lencana jumlah pesanan berstatus Verifikasi Pembayaran.
- Detail menampilkan bukti bayar (dapat diperbesar) berdampingan dengan nominal yang seharusnya dibayar.

**US-30 · Memverifikasi pembayaran (Must)**
As a admin, I want to menyetujui atau menolak bukti bayar so that hanya pesanan yang sudah dibayar diproses.
- Setujui → status **Diproses**. Tolak → alasan wajib diisi, status kembali **Menunggu Pembayaran** dan pelanggan dapat unggah ulang.
- Setiap keputusan tercatat (admin, waktu, alasan) pada log pesanan.

**US-31 · Mengubah status pesanan (Must)**
As a admin, I want to mengubah status pesanan so that pelanggan mengetahui progresnya.
- Perubahan hanya mengikuti transisi pada Bagian 4.3; transisi tidak valid ditolak dengan pesan.
- Perpindahan ke **Dikirim** mensyaratkan resi telah diinput (US-32).
- Pembatalan oleh admin pada status Verifikasi Pembayaran/Diproses mewajibkan alasan.

**US-32 · Menginput resi pengiriman (Must)**
As a admin, I want to menginput ekspedisi dan nomor resi secara manual so that pelanggan dapat melacak paket.
- Ekspedisi dipilih dari daftar (JNE, J&T, SiCepat, Pos Indonesia, Lainnya) `[ASUMSI]`; nomor resi alfanumerik 5–30 karakter.
- Resi dapat dikoreksi selama pesanan belum Selesai; koreksi tercatat di log.

**US-33 · Ringkasan statistik penjualan (Must)**
As a admin, I want to melihat statistik di dashboard so that saya memantau kinerja toko.
- Menampilkan total omzet, jumlah transaksi, 5 produk terlaris (berdasarkan jumlah unit), dan daftar varian dengan stok ≤ 3 `[ASUMSI]`.
- Omzet dihitung dari pesanan berstatus Diproses, Dikirim, dan Selesai `[ASUMSI]`.
- Filter periode: hari ini, 7 hari, 30 hari, bulan ini, rentang kustom; halaman termuat ≤ 2 detik pada 10.000 pesanan.

**US-34 · Mencetak rekap laporan penjualan (Must)**
As a admin, I want to mencetak rekap penjualan per periode so that pembukuan saya rapi.
- Pilih periode; laporan memuat tanggal, nomor pesanan, pelanggan, item, total, status, dan total keseluruhan.
- Keluaran PDF siap cetak A4; ekspor CSV/Excel bersifat Could.
- Total pada laporan identik dengan dashboard untuk periode yang sama.

**US-35 · Mengelola metode pembayaran & tarif ongkir (Must) `[TAMBAHAN]`**
As a admin, I want to mengatur rekening/e-wallet toko dan tarif ongkir per wilayah so that instruksi bayar dan estimasi ongkir benar.
- CRUD metode pembayaran (jenis, nama bank/e-wallet, nomor, atas nama, aktif/nonaktif).
- CRUD tarif ongkir flat per kota/kabupaten (dan kecamatan bila diperlukan) `[ASUMSI]`.
- Perubahan hanya berlaku untuk pesanan baru; pesanan lama menyimpan salinan nominalnya.

### 2.3 Daftar Layar

**Aplikasi pelanggan (Flutter):** Splash · Onboarding singkat · Login · Registrasi · Lupa/Reset Sandi · Beranda (banner, kategori, produk) · Hasil Cari/Filter · Detail Produk · Keranjang · Checkout · Pilih/Tambah Alamat · Instruksi Pembayaran & Unggah Bukti · Pesanan Saya · Detail Pesanan · Profil · Kelola Alamat · Ubah Sandi · Hapus Akun.

**Dashboard admin (web, responsif):** Login · Dashboard · Produk (daftar/form) · Kategori · Stok & Riwayat Stok · Pesanan (daftar/detail + verifikasi) · Metode Pembayaran · Tarif Ongkir · Laporan Penjualan · Pengaturan Akun.

### 2.4 Non-Goals (tidak dibangun pada MVP)

- Payment gateway otomatis (Midtrans/Xendit) — pembayaran tetap transfer + verifikasi manual (batasan proposal).
- Integrasi API ekspedisi/RajaOngkir untuk tarif dan pelacakan otomatis.
- Push notification promosi/status (FCM) dan notifikasi WhatsApp otomatis.
- Voucher/diskon/poin loyalti, wishlist, ulasan & rating produk, chat dalam aplikasi.
- Checkout sebagian item keranjang dan pembelian tanpa akun (guest checkout).
- Aplikasi mobile untuk admin dan peran admin berjenjang (kasir, gudang, dll.) — admin tunggal via web.
- Integrasi kasir/POS toko fisik dan sinkronisasi stok penjualan offline (stok offline dikoreksi lewat penyesuaian stok manual).
- Multi-bahasa dan multi-mata-uang (hanya Bahasa Indonesia dan Rupiah).
- Login sosial (Google/Facebook), verifikasi email/OTP, dan Flutter Web untuk pelanggan.
- Pengembalian barang/refund otomatis dan pelacakan resi di dalam aplikasi.

---

## 3. AI System Requirements

**Tidak berlaku.** Proposal tidak memuat fitur berbasis AI/LLM (tidak ada rekomendasi cerdas, chatbot, atau pencarian semantik). Pencarian pada MVP adalah pencocokan teks biasa (US-09). Strategi evaluasi kualitas untuk sistem ini ada di **Bagian 4.9 (Strategi Pengujian)**. Bila fitur AI ditambahkan pada versi mendatang (mis. rekomendasi produk), bagian ini harus diisi: kebutuhan tool/API, dataset evaluasi, dan ambang akurasi.

---

## 4. Technical Specifications

### 4.1 Architecture Overview

```
┌─────────────────────────┐        HTTPS / JSON         ┌──────────────────────────────┐
│ Aplikasi Pelanggan      │ ─────────────────────────▶ │ Backend CodeIgniter 4        │
│ Flutter (Android & iOS) │ ◀───────────────────────── │  • REST API  /api/v1  (JWT)  │
│  - state management TBD │     Authorization: Bearer   │  • Service layer & validasi  │
│  - secure storage (JWT) │                             │  • Cron: kedaluwarsa pesanan │
└─────────────────────────┘                             │                              │
                                                        │ Dashboard Admin (web)        │
┌─────────────────────────┐        HTTPS (session)      │  • CI4 views + Bootstrap     │
│ Browser Admin           │ ─────────────────────────▶ │  • Sesi + CSRF               │
│ (laptop / ponsel)       │ ◀───────────────────────── └──────────┬───────────┬───────┘
└─────────────────────────┘                                        │           │
                                                          ┌────────▼──┐  ┌─────▼──────────────┐
                                                          │  MySQL    │  │ File storage       │
                                                          │ (data)    │  │ foto produk (publik)│
                                                          └───────────┘  │ bukti bayar (privat)│
                                                                         └────────────────────┘
```

**Komponen & tanggung jawab**

| Komponen | Tanggung jawab |
|---|---|
| Aplikasi Flutter | UI pelanggan, validasi sisi klien, penyimpanan token aman, kompresi gambar, penanganan state loading/error/offline |
| REST API (CI4) | Autentikasi JWT, aturan bisnis (stok, harga, status), validasi sisi server, otorisasi per pengguna |
| Dashboard Admin (CI4 web) | Manajemen data master, verifikasi pembayaran, resi, laporan; memakai service layer dan database yang sama dengan API |
| MySQL | Penyimpanan data transaksional; transaksi database untuk operasi stok |
| File storage | Foto produk dilayani publik; bukti bayar hanya lewat endpoint terotorisasi |
| Cron job | Membatalkan pesanan kedaluwarsa, menyelesaikan pesanan otomatis, backup database harian |

**Alur data utama — Checkout**

1. Aplikasi memanggil `POST /orders` dengan `address_id`, `payment_method_id`, dan `Idempotency-Key`.
2. Server memuat keranjang pengguna, mengambil harga & stok **terbaru dari database**, lalu membuka transaksi DB.
3. Tiap varian dikunci (`SELECT … FOR UPDATE`), stok divalidasi lalu dikurangi, pesanan + item + salinan alamat disimpan, keranjang dikosongkan, dan `stock_movements` dicatat; transaksi di-commit.
4. Server mengembalikan nomor pesanan, total, dan instruksi bayar; aplikasi menampilkan layar pembayaran.
5. Pelanggan mengunggah bukti → `POST /orders/{id}/payment-proof` → status **Verifikasi Pembayaran**.
6. Admin memverifikasi di dashboard → status **Diproses** → input resi → **Dikirim**.

### 4.2 Technology Stack

Stack backend/admin mengikuti rencana proyek (CodeIgniter 4, MySQL, JWT, template Bootstrap). Item bertanda `[TBD]` perlu keputusan sebelum sprint pertama.

| Lapisan | Pilihan | Catatan |
|---|---|---|
| Aplikasi pelanggan | Flutter (channel stable) + Dart | Android & iOS dari satu basis kode |
| State management | `[TBD]` — kandidat Provider, GetX, Riverpod | Pilih satu dan tetapkan sebelum coding; rekomendasi penulis: pilih yang paling dikuasai tim agar 3 minggu coding realistis |
| Jaringan | `dio` atau `http` | Interceptor untuk token, refresh, dan penanganan error seragam |
| Penyimpanan token | `flutter_secure_storage` | Token tidak disimpan di SharedPreferences |
| Navigasi | `go_router` (usulan) | Deep link bisa ditambahkan kemudian |
| Gambar | `image_picker`, `cached_network_image`, kompresi gambar | Sesuai AC US-18 |
| Backend & API | CodeIgniter 4 (PHP 8.1+, sesuai syarat CI4) | Format respons JSON seragam |
| Auth pelanggan | JWT (access + refresh) | Access token 60 menit, refresh 30 hari `[ASUMSI]` |
| Auth admin | Sesi CI4 (mis. CI Shield) + CSRF | Terpisah dari JWT pelanggan |
| Database | MySQL / MariaDB (InnoDB, utf8mb4) | InnoDB wajib untuk transaksi dan row-lock |
| UI admin | Bootstrap (template Lumino atau DeskApp `[TBD]`) | Responsif desktop & mobile |
| Laporan PDF | DomPDF (usulan) | Keluaran A4 |
| Lingkungan dev | Laragon/XAMPP + MySQL lokal | Sesuai asumsi proposal |
| Hosting produksi | Cloud hosting 1 tahun + domain + SSL gratis | Harus mendukung PHP 8.1+, cron, ekstensi `intl`, `mbstring`, `gd`; penyedia `[TBD]` |
| Distribusi aplikasi | Android: APK/AAB; iOS: TestFlight/App Store `[TBD]` | Lihat risiko R3 dan R4 |

### 4.3 State Machine Pesanan

| Dari | Ke | Pemicu | Syarat | Efek |
|---|---|---|---|---|
| (baru) | Menunggu Pembayaran | Pelanggan membuat pesanan | Stok cukup | Stok berkurang; batas bayar = waktu buat + 24 jam |
| Menunggu Pembayaran | Verifikasi Pembayaran | Pelanggan unggah bukti | Bukti valid (MIME, ukuran) | Bukti tersimpan |
| Verifikasi Pembayaran | Diproses | Admin menyetujui | — | Log verifikasi |
| Verifikasi Pembayaran | Menunggu Pembayaran | Admin menolak | Alasan wajib | Pelanggan dapat unggah ulang; batas bayar tidak diperpanjang `[TBD]` |
| Diproses | Dikirim | Admin input resi | Ekspedisi + resi terisi | Resi tampil ke pelanggan |
| Dikirim | Selesai | Pelanggan konfirmasi atau otomatis 7 hari | — | Pesanan masuk laporan final |
| Menunggu Pembayaran | Dibatalkan | Pelanggan batal / kedaluwarsa 24 jam | — | Stok kembali |
| Verifikasi Pembayaran, Diproses | Dibatalkan | Admin membatalkan | Alasan wajib | Stok kembali; penanganan pengembalian dana manual di luar sistem |

Status **Selesai** dan **Dibatalkan** bersifat final. Semua transisi dicatat di `order_status_logs`.

### 4.4 Data Model (tingkat konseptual)

Skema final (ERD, LRS, SQL) dihasilkan pada fase Perancangan; berikut tabel dan kolom kunci yang dibutuhkan oleh requirement di atas.

| Tabel | Kolom Utama | Catatan |
|---|---|---|
| `users` | id, name, email (unik), phone (unik), password_hash, role (`customer`/`admin`), status, deleted_at | Admin dan pelanggan dibedakan oleh `role`/grup |
| `addresses` | id, user_id, label, recipient_name, recipient_phone, province, city, district, address_line, postal_code, is_default | Maks. 5 per pengguna |
| `categories` | id, name, slug, is_active | |
| `products` | id, category_id, name, description, price (int, rupiah), is_active, deleted_at | Soft delete |
| `product_variants` | id, product_id, color, size, sku, stock (int ≥ 0), is_active | Stok per varian; indeks pada product_id |
| `product_images` | id, product_id, path, sort_order | 1–5 per produk |
| `carts` / `cart_items` | cart: id, user_id (unik). item: cart_id, variant_id, qty | Unik (cart_id, variant_id) |
| `orders` | id, order_no (unik), user_id, status, subtotal, shipping_cost, total, address_snapshot (JSON), payment_method_snapshot (JSON), pay_before, created_at | Snapshot alamat & metode bayar |
| `order_items` | id, order_id, variant_id, product_name, variant_label, unit_price, qty, line_total | Menyimpan nama & harga saat beli |
| `payment_methods` | id, type (`bank`/`ewallet`), provider, account_no, account_name, is_active | Dikelola admin |
| `payment_proofs` | id, order_id, file_path (privat), status (`pending`/`approved`/`rejected`), reject_reason, reviewed_by, reviewed_at | Boleh >1 per pesanan (unggah ulang) |
| `shipments` | id, order_id, courier, tracking_no, shipped_at | |
| `shipping_rates` | id, region_name, cost, is_active | Tarif flat `[ASUMSI]` |
| `stock_movements` | id, variant_id, type (`order`/`cancel`/`adjust`), qty_change, stock_before, stock_after, reason, ref_order_id, admin_id, created_at | Audit stok |
| `order_status_logs` | id, order_id, from_status, to_status, note, actor_id, created_at | Audit status |
| `refresh_tokens` / `password_resets` | token_hash, user_id, expires_at, used_at | Token disimpan sebagai hash |

Aturan integritas: semua uang bertipe integer rupiah; kunci asing dengan indeks; `stock >= 0` dijaga oleh aplikasi dan constraint/trigger bila memungkinkan.

### 4.5 Kontrak API (REST, prefix `/api/v1`, JSON)

Format sukses `{ "data": …, "meta": … }`; format error `{ "error": { "code": "…", "message": "…", "fields": {…} } }`. Zona waktu respons ISO 8601 dengan offset `+07:00` (WIB).

| Metode | Endpoint | Auth | Deskripsi | Story |
|---|---|---|---|---|
| POST | `/auth/register` | — | Daftar akun + alamat pertama | US-01 |
| POST | `/auth/login` | — | Login, kembalikan access & refresh token | US-02 |
| POST | `/auth/refresh` | refresh | Tukar refresh token | US-02 |
| POST | `/auth/logout` | JWT | Batalkan refresh token | US-02 |
| POST | `/auth/forgot-password` | — | Kirim tautan/kode reset | US-03 |
| POST | `/auth/reset-password` | — | Setel kata sandi baru | US-03 |
| GET / PUT | `/me` | JWT | Lihat / ubah profil | US-04 |
| PUT | `/me/password` | JWT | Ubah kata sandi | US-04 |
| DELETE | `/me` | JWT | Hapus (anonimkan) akun | US-06 |
| GET / POST | `/me/addresses` | JWT | Daftar / tambah alamat | US-05 |
| PUT / DELETE | `/me/addresses/{id}` | JWT | Ubah / hapus alamat | US-05 |
| GET | `/categories` | — | Daftar kategori aktif | US-10 |
| GET | `/products?q=&category_id=&page=&per_page=` | — | Daftar, cari, filter | US-07, 09, 10 |
| GET | `/products/{id}` | — | Detail + varian + stok | US-08 |
| GET | `/cart` | JWT | Isi keranjang + total | US-11–13 |
| POST | `/cart/items` | JWT | Tambah item | US-11 |
| PATCH / DELETE | `/cart/items/{id}` | JWT | Ubah qty / hapus item | US-12 |
| DELETE | `/cart` | JWT | Kosongkan keranjang | US-12 |
| GET | `/checkout/summary?address_id=` | JWT | Ringkasan + ongkir | US-15 |
| GET | `/payment-methods` | JWT | Metode bayar aktif | US-17 |
| POST | `/orders` | JWT + `Idempotency-Key` | Buat pesanan | US-16 |
| GET | `/orders?status=&page=` | JWT | Riwayat pesanan | US-19 |
| GET | `/orders/{id}` | JWT (pemilik) | Detail pesanan + linimasa + resi | US-19, 20 |
| POST | `/orders/{id}/payment-proof` | JWT (pemilik) | Unggah bukti bayar (multipart) | US-18 |
| POST | `/orders/{id}/cancel` | JWT (pemilik) | Batalkan pesanan | US-21 |
| POST | `/orders/{id}/complete` | JWT (pemilik) | Konfirmasi diterima | US-22 |

Kode status standar: `200/201` sukses · `401` belum login/token invalid · `403` bukan pemilik · `404` tidak ditemukan · `409` konflik (mis. stok tidak cukup, transisi tidak valid) · `422` validasi gagal · `429` terlalu banyak percobaan.

Fungsi admin (US-23 s.d. US-35) dilayani oleh controller dashboard web, bukan oleh API publik.

### 4.6 Integration Points

| Integrasi | Status MVP | Keterangan |
|---|---|---|
| Layanan email (SMTP) | Dibutuhkan untuk US-03 | Penyedia `[TBD]`; pada hosting umum gunakan SMTP hosting atau layanan gratis berkuota |
| Payment gateway | Tidak ada | Versi 1.1 (Midtrans/Xendit) |
| API ekspedisi / RajaOngkir | Tidak ada | Versi 1.1 |
| Firebase Cloud Messaging | Tidak ada | Versi 1.1 |
| WhatsApp | Hanya tautan "Hubungi Toko" (deep link `wa.me`) `[ASUMSI]` | Tanpa WhatsApp Business API |

### 4.7 Non-Functional Requirements

| Kategori | Persyaratan terukur |
|---|---|
| **Performa API** | p95 ≤ 500 ms untuk `GET /products` (20 item/halaman) pada 1.000 produk dan 50 pengguna bersamaan; p95 ≤ 800 ms untuk `POST /orders` |
| **Performa aplikasi** | Waktu buka dingin ≤ 3 detik dan Beranda terisi ≤ 2 detik (jaringan 4G) pada Android kelas menengah (RAM 4 GB); scroll ≥ 55 FPS pada daftar produk |
| **Ukuran data gambar** | Kartu produk memuat thumbnail ≤ 60 KB; foto detail ≤ 250 KB |
| **Ketersediaan** | ≥ 99% per bulan pada jam 07.00–22.00 WIB (bergantung SLA hosting) |
| **Kompatibilitas** | Android 6.0+ (API 23) dan iOS 13+ `[ASUMSI]`; layar mulai 360 dp lebar; teks mengikuti pengaturan ukuran font sistem |
| **Aksesibilitas** | Area ketuk ≥ 48 dp; kontras teks ≥ 4,5:1; semua gambar produk memiliki label semantik |
| **Lokalisasi** | Bahasa Indonesia; format `Rp 1.250.000`; tanggal `14 Nov 2026, 14.30 WIB` |
| **Ketahanan jaringan** | Timeout 15 detik, percobaan ulang otomatis 2 kali untuk GET; pesan error jelas saat offline; pesanan tidak pernah ganda (idempotensi) |
| **Pemeliharaan** | Backup database otomatis harian, retensi 7 hari, uji pulih (restore) minimal sekali sebelum go-live; log aplikasi & error terpusat |
| **Skalabilitas awal** | Dirancang nyaman untuk ≤ 500 pesanan/bulan dan ≤ 2.000 pengguna (volume saat ini ± 30 item/bulan; ruang tumbuh 15×) |

### 4.8 Security & Privacy

**Keamanan**

- Seluruh lalu lintas HTTPS (TLS 1.2+); HTTP dialihkan ke HTTPS; HSTS aktif.
- Kata sandi di-hash (bcrypt/argon2 melalui library autentikasi); tidak pernah dicatat di log.
- JWT bertanda tangan dengan secret di variabel lingkungan (`.env`), bukan di repository; refresh token disimpan sebagai hash dan dapat dicabut.
- Pembatasan laju (rate limit): login & reset sandi 5 percobaan/15 menit; API umum 120 permintaan/menit per pengguna `[ASUMSI]`.
- Otorisasi di server pada **setiap** endpoint berdasarkan pemilik sumber daya (mencegah IDOR: pelanggan hanya dapat membaca pesanan/alamat/keranjang miliknya).
- Seluruh input divalidasi di server; query memakai query builder/prepared statement (anti SQL injection); output admin di-escape (anti XSS); formulir admin memakai CSRF token.
- Unggahan: validasi MIME sebenarnya (bukan hanya ekstensi), nama file diacak, tidak dapat dieksekusi; **bukti bayar disimpan di luar direktori publik** dan hanya dapat dibuka oleh pemilik pesanan dan admin.
- Kunci/secret tidak disematkan di aplikasi Flutter; build rilis memakai obfuscation (`--obfuscate --split-debug-info`).
- Akun admin: kata sandi kuat (≥ 12 karakter), sesi idle 30 menit; audit log untuk verifikasi pembayaran, perubahan stok, dan pembatalan.

**Privasi & kepatuhan**

- Data pribadi yang dikumpulkan: nama, email, nomor telepon, alamat, dan bukti pembayaran. Dikumpulkan seperlunya untuk pemrosesan pesanan.
- Aplikasi menyediakan Kebijakan Privasi dan persetujuan pengguna saat registrasi, sejalan dengan UU No. 27 Tahun 2022 tentang Pelindungan Data Pribadi; teks kebijakan perlu ditinjau pihak yang berwenang `[TBD]`.
- Hak pengguna: melihat/mengubah data (US-04, US-05) dan menghapus akun (US-06).
- Bukti bayar dapat memuat nomor rekening pengirim; akses dibatasi dan retensi ditetapkan `[TBD]` (usulan: dihapus 12 bulan setelah pesanan Selesai).
- Pesanan yang dianonimkan tetap disimpan untuk keperluan pembukuan.

### 4.9 Strategi Pengujian & Definition of Done

| Jenis uji | Cakupan | Alat / Metode | Penanggung jawab | Kriteria lulus |
|---|---|---|---|---|
| Unit test Flutter | Hitung keranjang, validator form, parsing model, format Rupiah | `flutter_test` | Pengembang | ≥ 70% cakupan pada logika bisnis & validator |
| Widget/UI test | Alur Login, Tambah ke Keranjang, Checkout | `flutter_test`, `integration_test` | Pengembang | Skenario utama lulus di Android emulator |
| Uji API | Seluruh endpoint §4.5, termasuk kasus gagal (401/403/409/422) | Postman/Newman atau CI4 feature test | Pengembang backend + QA | 100% endpoint punya uji sukses dan gagal |
| Uji konkurensi stok | 2–20 permintaan serentak pada stok terakhir | Skrip paralel | QA | Tepat 1 pesanan berhasil; stok tidak negatif |
| Black-box (proposal) | Seluruh story Must: validasi input, batas nilai, alur status | Tabel test case | QA (Muhammad Ivan A.) | 100% kasus Must lulus |
| Keamanan dasar | IDOR, SQL injection, XSS, unggahan berbahaya, brute force | Checklist OWASP MASVS/ASVS ringkas | QA | Tidak ada temuan Critical/High |
| Performa | `GET /products`, `POST /orders` | k6/JMeter ringan | QA | Sesuai §4.7 |
| Perangkat | ≥ 3 perangkat Android (versi & ukuran layar berbeda), ≥ 1 iPhone `[TBD]` | Uji manual | QA | Tanpa crash; tata letak tidak terpotong |
| UAT | Skenario nyata bersama pemilik toko | Skrip UAT + lembar persetujuan | QA + Rafly Ikhsanida | 100% skenario Must disetujui tertulis |

**Definition of Done (per story):** semua AC terpenuhi · lolos code review · uji unit/API terkait lulus · tidak ada bug Critical/High · string UI dalam Bahasa Indonesia · terdokumentasi di Postman collection dan user manual bila menyentuh fitur admin.

**Release Criteria (go-live):** seluruh story Must selesai dan lulus UAT · backup & restore teruji · HTTPS aktif · data master awal (produk, foto, stok, rekening) terisi · akun admin produksi dibuat dan sandi default dihapus · user manual diserahkan · pelatihan admin selesai.

### 4.10 Lingkungan & Deployment

| Lingkungan | Tujuan | Catatan |
|---|---|---|
| Local | Pengembangan | Laragon/XAMPP, database lokal |
| Staging | UAT bersama pemilik | Subdomain terpisah dengan data uji; APK uji dibagikan langsung |
| Production | Layanan nyata | Domain utama, HTTPS, cron aktif, backup harian |

Pipeline sederhana: kode di Git (cabang `main` = produksi, `develop` = integrasi); migrasi database memakai CI4 Migrations; rilis API manual lewat unggah/`git pull` ke hosting; versi aplikasi mengikuti `MAJOR.MINOR.PATCH+build`.

---

## 5. Risks & Roadmap

### 5.1 Phased Rollout

| Fase | Cakupan | Kriteria Keluar |
|---|---|---|
| **MVP — v1.0** | Seluruh story **Must** (US-01–05, 07–20, 23–35) dan story **Should** yang muat jadwal (US-06, 21, 22). Aplikasi Android; backend + dashboard admin web; pembayaran transfer manual; resi manual | Release Criteria §4.9 terpenuhi; UAT disetujui pemilik toko; KPI K1–K5 mulai diukur |
| **v1.1** | Payment gateway (Midtrans/Xendit) untuk verifikasi otomatis · integrasi RajaOngkir (tarif & pelacakan resi) · push notification FCM untuk perubahan status & promosi · verifikasi email · ekspor laporan Excel · harga berbeda per varian · checkout sebagian item · security patching berkala | ≥ 80% pembayaran terverifikasi otomatis; median verifikasi < 5 menit; ongkir tanpa input manual |
| **v2.0** | Wishlist & ulasan produk · voucher/promo · peran admin berjenjang (kasir/gudang) · aplikasi admin mobile · sinkronisasi stok dengan penjualan toko fisik · analitik lanjutan (tren, pelanggan berulang) · rilis iOS resmi bila belum selesai di MVP | Ditetapkan setelah evaluasi data penjualan v1.1 |

### 5.2 Jadwal Pelaksanaan (model Waterfall, 12 minggu menurut proposal)

Tanggal pada proposal (5 Jan – 29 Mar 2026) sudah terlewat, sehingga jadwal di bawah memakai **minggu relatif**; tanggal mulai `[TBD]`. Penanggung jawab mengikuti WBS proposal.

| Minggu | Fase | Keluaran Utama | PJ (menurut proposal) |
|---|---|---|---|
| 1–2 | Analisis & Perencanaan | PRD ini disetujui, keputusan `[TBD]` pada Lampiran C ditutup | Fahrul Rozi |
| 3–4 | Perancangan Sistem | ERD/LRS, Use Case & Activity Diagram, wireframe & UI/UX aplikasi Flutter dan admin | Feliks Gabriel, Almira Safa Aqila, Muhammad Ivan A. |
| 5–7 | Pengembangan | Database + API + dashboard admin + aplikasi Flutter (modul pelanggan) + integrasi bukti bayar & resi | Feliks Gabriel (utama), Almira Safa Aqila |
| 8–9 | Pengujian | Black-box, uji API, uji konkurensi stok, perbaikan bug, UAT bersama pemilik | Muhammad Ivan A., Feliks Gabriel |
| 10 | Implementasi & Deployment | Hosting, domain, SSL, migrasi database, publikasi APK | Fahrul Rozi, Muhammad Ivan A. |
| 11 | Pelatihan & Serah Terima | Pelatihan dashboard admin, user manual | Almira Safa Aqila, Feliks Gabriel |
| 12 | Laporan Akhir & Evaluasi | Dokumentasi akhir, evaluasi KPI awal | Seluruh anggota |

**Catatan kelayakan jadwal.** Proposal mengalokasikan 3 minggu coding untuk aplikasi **web**. Dengan Flutter, pekerjaan bertambah (aplikasi mobile + REST API + dashboard admin web) dan sebagian besar pengembangan ditumpukan pada satu orang. Dua opsi:

- **Opsi A — tetap 12 minggu:** cakupan dipotong ke story Must saja (tunda US-06, 21, 22), rilis Android saja, UI admin memakai template siap pakai tanpa kustomisasi.
- **Opsi B — 15 minggu (rekomendasi penulis bila iOS atau story Should masuk):** fase Pengembangan diperpanjang menjadi 6 minggu; API + dashboard admin dan aplikasi Flutter dikerjakan paralel oleh dua orang berbeda.

### 5.3 Technical & Project Risks

Kemungkinan (K) / Dampak (D): T = Tinggi, S = Sedang, R = Rendah.

| ID | Risiko | K | D | Mitigasi |
|---|---|---|---|---|
| R1 | Jadwal tidak cukup untuk Flutter + API + admin dengan tim kecil | T | T | Pilih Opsi A/B (§5.2); kunci scope di PRD; demo mingguan; fitur Should dapat digeser |
| R2 | Ketidakkonsistenan anggaran: proposal menyebut batas Rp 2.500.000 tetapi tabel mencantumkan total Rp 7.000.000 (rincian item berjumlah Rp 2.500.000) | T | S | Pastikan angka final dengan dosen/klien sebelum pembelian hosting; lihat Lampiran B |
| R3 | Biaya publikasi toko aplikasi tidak ada di anggaran (Google Play ± US$25 sekali bayar; Apple Developer ± US$99/tahun) | T | S | Pada MVP bagikan APK langsung dan uji iOS via TestFlight bila akun ada; masukkan biaya toko aplikasi ke RAB bila ingin publik `[TBD]` |
| R4 | Build iOS membutuhkan Mac dan akun Apple Developer yang belum tentu tersedia | S | S | Tetapkan iOS di luar MVP bila perangkat belum ada; jaga kode tetap lintas platform |
| R5 | Stok ganda terjual (race condition) saat dua pelanggan membeli stok terakhir | S | T | Transaksi DB + `SELECT … FOR UPDATE`; uji konkurensi wajib lulus (§4.9) |
| R6 | Data master (foto, harga, varian, stok) terlambat atau tidak lengkap | S | S | Template pengisian data; tenggat penyerahan di minggu 4; admin dapat mengisi bertahap |
| R7 | Pemilik tunggal menjadi bottleneck verifikasi pembayaran dan stok | S | S | Dashboard dengan antrean & lencana verifikasi; target KPI K3 realistis; pertimbangkan pembantu toko di v2.0 |
| R8 | Pelanggan enggan memasang aplikasi dibanding memesan lewat WhatsApp | T | T | Tautan unduh/QR di bio Instagram, spanduk toko, dan pesan balasan WhatsApp; insentif pesanan pertama `[TBD]`; pantau KPI K1 |
| R9 | Hosting umum terbatas (versi PHP, cron, memori) atau lambat | S | S | Verifikasi spesifikasi hosting sebelum membeli; uji performa di staging |
| R10 | Kebocoran data (bukti bayar, alamat) atau pembobolan akun | R | T | Kontrol §4.8: penyimpanan privat, IDOR check, rate limit, HTTPS, audit log |
| R11 | Penolakan toko aplikasi (kebijakan privasi, hapus akun, izin) | S | S | US-06, kebijakan privasi tersedia, izin minimum (kamera/galeri hanya saat unggah) |
| R12 | Ongkir manual tidak akurat sehingga toko rugi | S | S | Tarif per wilayah dikelola admin, ditinjau berkala; RajaOngkir di v1.1 |
| R13 | Email reset sandi masuk spam / SMTP hosting terbatas | S | R | Gunakan domain dengan SPF/DKIM; sediakan jalur bantuan lewat WhatsApp toko |
| R14 | Perubahan peran/ketersediaan anggota tim | S | S | Dokumentasi kode, pembagian modul jelas, repository bersama |

---

## 6. Lampiran

### Lampiran A — Keterlacakan Requirement ke Proposal

| Bagian proposal | Ringkasan | Story |
|---|---|---|
| 2.2.1 Pendaftaran & autentikasi | Registrasi, login/logout, lupa sandi, profil, alamat | US-01–05 (+ US-06) |
| 2.2.2 Katalog | Daftar, detail, pencarian, filter kategori | US-07–10 |
| 2.2.3 Keranjang | Tambah, ubah, hapus, kosongkan, total otomatis | US-11–13 |
| 2.2.4 Checkout & pemesanan | Checkout, pilih alamat, ringkasan, nomor pesanan | US-14–16 |
| 2.2.5 Pembayaran & bukti | Metode, unggah bukti, riwayat status, lihat resi | US-17–20 (+ US-21, 22) |
| 2.2.6 Autentikasi pengelola | Login admin, CRUD produk, kategori, foto & varian | US-23–26 |
| 2.2.7 Manajemen stok | Penyesuaian stok, stok otomatis, daftar pesanan, verifikasi, ubah status | US-27–31 |
| 2.2.8 Manajemen pengiriman | Input resi, statistik dashboard | US-32, 33 |
| 1.4 Ruang lingkup — rekapitulasi laporan | Cetak rekap penjualan | US-34 |
| Kebutuhan pendukung (tidak eksplisit) | Metode bayar & ongkir yang dikelola admin | US-35 `[TAMBAHAN]` |
| 3.2 Saran → Roadmap | Payment gateway, RajaOngkir, mobile native + push, backup & keamanan | v1.1 (§5.1), backup harian di §4.7 |

### Lampiran B — Selisih & Isu yang Ditemukan pada Proposal

| # | Temuan | Dampak pada PRD |
|---|---|---|
| B1 | **Platform:** proposal (1.4, 2.1.5) menetapkan aplikasi berbasis web; keputusan terbaru adalah Flutter. Proposal 3.2 sendiri menyarankan mobile native sebagai pengembangan lanjutan | Sisi pelanggan menjadi aplikasi Flutter; sisi admin tetap web `[ASUMSI]`. Proposal/laporan perlu direvisi agar konsisten |
| B2 | **Anggaran:** kendala 2.6.2 membatasi biaya maksimal Rp 2.500.000, sedangkan Tabel 3 mencantumkan total Rp 7.000.000. Penjumlahan rincian item pada Tabel 3 = Rp 2.500.000 | Angka final harus dikoreksi; biaya toko aplikasi dan tambahan Flutter belum tercakup (R2, R3) |
| B3 | **Jadwal:** seluruh tanggal WBS (5 Jan – 29 Mar 2026) sudah lewat per dokumen ini; usaha RnZ Store sendiri berdiri 29 Jan 2026, setelah fase analisis pada WBS dimulai | Jadwal dipakai sebagai minggu relatif; tanggal baru `[TBD]` |
| B4 | **Peran tim tidak konsisten:** bagian 2.4.1 menempatkan Almira sebagai DBA/Backend dan Feliks sebagai UI/UX + Full-stack, tetapi WBS menugaskan desain database ke Feliks dan use case diagram ke Muhammad Ivan, sementara 2.4.2 menugaskan use case diagram ke Almira | PJ pada §5.2 mengikuti WBS; perlu diselaraskan oleh tim |
| B5 | **Estimasi ongkir:** checkout (2.2.4) menampilkan "Estimasi Ongkir", namun proposal tidak memiliki sumber tarif (tanpa API ekspedisi) | Diselesaikan sementara dengan tarif flat per wilayah (US-35) `[ASUMSI]` |
| B6 | **Pengelompokan fitur:** verifikasi pembayaran dan ubah status pesanan berada di bawah "Manajemen Stok" (2.2.7); statistik dashboard di bawah "Pengiriman" (2.2.8) | Dipetakan ulang ke Epic F secara logis; isi tidak berubah |
| B7 | **Sifat dokumen:** Bab III (Kesimpulan) menyatakan seluruh tujuan "telah dicapai", padahal dokumen berupa rencana proyek | Bukan masalah PRD; perlu penyesuaian redaksi pada laporan |
| B8 | **Typo/penamaan** (mis. "Costumer", "Process Checkout", "Penutupan") | Tidak berdampak pada PRD |

### Lampiran C — Pertanyaan Terbuka / Keputusan yang Dibutuhkan

| # | Pertanyaan | Pemilik Keputusan | Dibutuhkan Sebelum |
|---|---|---|---|
| C1 | Berapa anggaran final (Rp 2,5 juta atau Rp 7 juta), dan apakah biaya Google Play/Apple Developer ditanggung? | Dosen & pemilik toko | Minggu 2 |
| C2 | Apakah iOS masuk MVP? Apakah tim memiliki Mac dan akun Apple Developer? | Tim | Minggu 2 |
| C3 | Dashboard admin tetap web (CI4) seperti asumsi, atau diinginkan juga sebagai aplikasi? | Pemilik toko & tim | Minggu 2 |
| C4 | State management Flutter: Provider, GetX, atau Riverpod? | Tim pengembang | Minggu 3 |
| C5 | Opsi jadwal A (12 minggu, scope dipotong) atau B (15 minggu)? Tanggal mulai? | Dosen & tim | Minggu 2 |
| C6 | Sumber estimasi ongkir pada MVP: tarif flat per wilayah, atau dikonfirmasi admin via WhatsApp? Bagaimana jika wilayah belum ada tarif? | Pemilik toko | Minggu 3 |
| C7 | Batas waktu bayar 24 jam sudah sesuai? Apakah penolakan bukti memperpanjang batas waktu? | Pemilik toko | Minggu 3 |
| C8 | Harga sama untuk semua varian, atau bisa berbeda per varian? | Pemilik toko | Minggu 3 |
| C9 | Perlukah verifikasi email/OTP saat registrasi? Penyedia SMTP yang dipakai? | Tim | Minggu 4 |
| C10 | Metode pembayaran apa saja yang aktif (bank, e-wallet apa)? Daftar ekspedisi yang dipakai? | Pemilik toko | Minggu 4 |
| C11 | Definisi omzet pada dashboard: total termasuk ongkir, atau hanya nilai produk? | Pemilik toko | Minggu 4 |
| C12 | Kebijakan retensi bukti bayar dan teks Kebijakan Privasi | Tim & dosen | Minggu 8 |
| C13 | Penyedia hosting & domain (nama domain, spesifikasi PHP/cron) | Tim | Minggu 8 |
| C14 | Apakah target KPI K1–K5 dapat diterima pemilik toko? | Pemilik toko | Minggu 2 |

### Persetujuan Dokumen

| Peran | Nama | Tanda Tangan | Tanggal |
|---|---|---|---|
| Product Owner / Klien | Rafly Ikhsanida | | |
| Project Leader / System Analyst | Fahrul Rozi | | |
| Lead Developer / UI-UX | Feliks Gabriel | | |
| Backend & Database | Almira Safa Aqila | | |
| QA & Tester | Muhammad Ivan Abdullah | | |
| Dosen Pengampu | Mia Rosmiati | | |

*— Akhir dokumen —*
