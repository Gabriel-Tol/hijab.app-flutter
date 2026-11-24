<?= $this->extend('admin/layouts/main') ?>

<?= $this->section('content') ?>
<div class="mb-4">
    <a href="/admin/products" class="text-decoration-none small" style="color: var(--rnz-muted);"><i class="bi bi-arrow-left me-1"></i> Kembali ke Daftar Produk</a>
    <h5 class="fw-bold font-serif mt-1">Tambah Produk Hijab Baru</h5>
</div>

<form action="/admin/products/store" method="POST" enctype="multipart/form-data">
    <?= csrf_field() ?>
    <div class="row g-4">
        <!-- Kolom Kiri: Informasi Produk & Foto -->
        <div class="col-12 col-lg-7">
            <div class="card border-0 shadow-sm rounded-3 mb-4">
                <div class="card-header bg-white py-3 border-bottom">
                    <h6 class="mb-0 fw-bold">Informasi Utama</h6>
                </div>
                <div class="card-body p-4">
                    <div class="mb-3">
                        <label class="form-label small fw-semibold">Nama Produk Hijab <span class="text-danger">*</span></label>
                        <input type="text" name="name" class="form-control" placeholder="Contoh: Pashmina Viscose Silk" value="<?= old('name') ?>" required>
                    </div>

                    <div class="row g-3 mb-3">
                        <div class="col-12 col-sm-6">
                            <label class="form-label small fw-semibold">Kategori <span class="text-danger">*</span></label>
                            <select name="category_id" class="form-select" required>
                                <option value="">Pilih Kategori</option>
                                <?php foreach ($categories as $cat): ?>
                                    <option value="<?= $cat['id'] ?>" <?= old('category_id') == $cat['id'] ? 'selected' : '' ?>>
                                        <?= esc($cat['name']) ?>
                                    </option>
                                <?php endforeach; ?>
                            </select>
                        </div>
                        <div class="col-12 col-sm-6">
                            <label class="form-label small fw-semibold">Harga Jual (Rp) <span class="text-danger">*</span></label>
                            <div class="input-group">
                                <span class="input-group-text bg-light">Rp</span>
                                <input type="number" name="price" class="form-control" placeholder="85000" value="<?= old('price') ?>" required min="0">
                            </div>
                        </div>
                    </div>

                    <div class="mb-3">
                        <label class="form-label small fw-semibold">Deskripsi Produk</label>
                        <textarea name="description" class="form-control" rows="4" placeholder="Jelaskan karakteristik bahan, keunggulan, dan saran pemakaian..."><?= old('description') ?></textarea>
                    </div>

                    <div class="form-check form-switch mt-3">
                        <input class="form-check-input" type="checkbox" name="is_active" value="1" id="activeProduct" checked>
                        <label class="form-check-label small" for="activeProduct">Aktifkan produk untuk ditampilkan di katalog aplikasi</label>
                    </div>
                </div>
            </div>

            <!-- Upload Galeri Foto -->
            <div class="card border-0 shadow-sm rounded-3">
                <div class="card-header bg-white py-3 border-bottom">
                    <h6 class="mb-0 fw-bold">Foto Produk (1 - 5 Gambar)</h6>
                </div>
                <div class="card-body p-4">
                    <input type="file" name="images[]" class="form-control mb-2" accept="image/jpeg,image/png,image/webp" multiple>
                    <small class="text-muted d-block">Format: JPG, PNG, atau WEBP. Maksimal 2 MB per file.</small>
                </div>
            </div>
        </div>

        <!-- Kolom Kanan: Varian Produk (Warna & Ukuran) -->
        <div class="col-12 col-lg-5">
            <div class="card border-0 shadow-sm rounded-3">
                <div class="card-header bg-white py-3 d-flex justify-content-between align-items-center border-bottom">
                    <h6 class="mb-0 fw-bold">Varian Produk & Stok</h6>
                    <button type="button" class="btn btn-sm btn-outline-rnz" onclick="addVariantRow()">
                        <i class="bi bi-plus-lg me-1"></i> Tambah Varian
                    </button>
                </div>
                <div class="card-body p-4">
                    <div id="variantContainer">
                        <div class="border rounded p-3 mb-3 bg-light variant-row">
                            <div class="mb-2">
                                <label class="form-label small fw-semibold">Warna / Corak <span class="text-danger">*</span></label>
                                <input type="text" name="variant_color[]" class="form-control form-control-sm" placeholder="Contoh: Dusty Pink" required>
                            </div>
                            <div class="row g-2 mb-2">
                                <div class="col-6">
                                    <label class="form-label small fw-semibold">Ukuran</label>
                                    <input type="text" name="variant_size[]" class="form-control form-control-sm" value="All Size">
                                </div>
                                <div class="col-6">
                                    <label class="form-label small fw-semibold">Stok Awal <span class="text-danger">*</span></label>
                                    <input type="number" name="variant_stock[]" class="form-control form-control-sm" value="10" min="0" required>
                                </div>
                            </div>
                            <div>
                                <label class="form-label small fw-semibold">SKU / Kode (Opsional)</label>
                                <input type="text" name="variant_sku[]" class="form-control form-control-sm" placeholder="Contoh: PASH-DP-01">
                            </div>
                        </div>
                    </div>

                    <div class="mt-4">
                        <button type="submit" class="btn btn-rnz w-100 py-2">
                            <i class="bi bi-check-lg me-1"></i> Simpan Produk & Varian
                        </button>
                    </div>
                </div>
            </div>
        </div>
    </div>
</form>

<script>
    function addVariantRow() {
        const container = document.getElementById('variantContainer');
        const row = document.createElement('div');
        row.className = 'border rounded p-3 mb-3 bg-light variant-row position-relative';
        row.innerHTML = `
            <button type="button" class="btn btn-sm btn-danger position-absolute top-0 end-0 m-2 py-0 px-2" onclick="this.parentElement.remove()">×</button>
            <div class="mb-2 pe-4">
                <label class="form-label small fw-semibold">Warna / Corak <span class="text-danger">*</span></label>
                <input type="text" name="variant_color[]" class="form-control form-control-sm" placeholder="Contoh: Mocca / Sage Green" required>
            </div>
            <div class="row g-2 mb-2">
                <div class="col-6">
                    <label class="form-label small fw-semibold">Ukuran</label>
                    <input type="text" name="variant_size[]" class="form-control form-control-sm" value="All Size">
                </div>
                <div class="col-6">
                    <label class="form-label small fw-semibold">Stok Awal <span class="text-danger">*</span></label>
                    <input type="number" name="variant_stock[]" class="form-control form-control-sm" value="10" min="0" required>
                </div>
            </div>
            <div>
                <label class="form-label small fw-semibold">SKU / Kode (Opsional)</label>
                <input type="text" name="variant_sku[]" class="form-control form-control-sm" placeholder="Contoh: PASH-MC-02">
            </div>
        `;
        container.appendChild(row);
    }
</script>
<?= $this->endSection() ?>
