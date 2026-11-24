<?= $this->extend('admin/layouts/main') ?>

<?= $this->section('content') ?>
<div class="mb-4">
    <a href="/admin/products" class="text-decoration-none small" style="color: var(--rnz-muted);"><i class="bi bi-arrow-left me-1"></i> Kembali ke Daftar Produk</a>
    <h5 class="fw-bold font-serif mt-1">Ubah Produk: <?= esc($product['name']) ?></h5>
</div>

<form action="/admin/products/update/<?= $product['id'] ?>" method="POST" enctype="multipart/form-data">
    <?= csrf_field() ?>
    <div class="row g-4">
        <!-- Kolom Kiri: Informasi Utama & Galeri Foto -->
        <div class="col-12 col-lg-7">
            <div class="card border-0 shadow-sm rounded-3 mb-4">
                <div class="card-header bg-white py-3 border-bottom">
                    <h6 class="mb-0 fw-bold">Informasi Utama</h6>
                </div>
                <div class="card-body p-4">
                    <div class="mb-3">
                        <label class="form-label small fw-semibold">Nama Produk Hijab <span class="text-danger">*</span></label>
                        <input type="text" name="name" class="form-control" value="<?= esc($product['name']) ?>" required>
                    </div>

                    <div class="row g-3 mb-3">
                        <div class="col-12 col-sm-6">
                            <label class="form-label small fw-semibold">Kategori <span class="text-danger">*</span></label>
                            <select name="category_id" class="form-select" required>
                                <?php foreach ($categories as $cat): ?>
                                    <option value="<?= $cat['id'] ?>" <?= ($product['category_id'] == $cat['id']) ? 'selected' : '' ?>>
                                        <?= esc($cat['name']) ?>
                                    </option>
                                <?php endforeach; ?>
                            </select>
                        </div>
                        <div class="col-12 col-sm-6">
                            <label class="form-label small fw-semibold">Harga Jual (Rp) <span class="text-danger">*</span></label>
                            <div class="input-group">
                                <span class="input-group-text bg-light">Rp</span>
                                <input type="number" name="price" class="form-control" value="<?= $product['price'] ?>" required min="0">
                            </div>
                        </div>
                    </div>

                    <div class="mb-3">
                        <label class="form-label small fw-semibold">Deskripsi Produk</label>
                        <textarea name="description" class="form-control" rows="4"><?= esc($product['description'] ?? '') ?></textarea>
                    </div>

                    <div class="form-check form-switch mt-3">
                        <input class="form-check-input" type="checkbox" name="is_active" value="1" id="activeProduct" <?= $product['is_active'] ? 'checked' : '' ?>>
                        <label class="form-check-label small" for="activeProduct">Tampilkan di aplikasi pelanggan</label>
                    </div>
                </div>
            </div>

            <!-- Galeri Foto Saat Ini & Upload Tambahan -->
            <div class="card border-0 shadow-sm rounded-3">
                <div class="card-header bg-white py-3 border-bottom">
                    <h6 class="mb-0 fw-bold">Foto Produk</h6>
                </div>
                <div class="card-body p-4">
                    <?php if (!empty($images)): ?>
                        <label class="form-label small fw-semibold text-muted d-block mb-2">Foto Terpasang:</label>
                        <div class="d-flex flex-wrap gap-3 mb-4">
                            <?php foreach ($images as $img): ?>
                                <div class="position-relative border rounded p-1 bg-light" style="width: 90px; height: 90px;">
                                    <img src="/<?= esc($img['file_path']) ?>" class="rounded w-100 h-100" style="object-fit: cover;">
                                    <button type="submit" form="deleteImgForm<?= $img['id'] ?>" class="btn btn-sm btn-danger position-absolute top-0 end-0 py-0 px-1 m-1" title="Hapus foto" onclick="return rnzConfirm('Hapus foto ini?', this, '/admin/products/delete-image/<?= $img['id'] ?>')">
                                        <i class="bi bi-trash"></i>
                                    </button>
                                </div>
                            <?php endforeach; ?>
                        </div>
                    <?php endif; ?>

                    <label class="form-label small fw-semibold">Upload Foto Tambahan</label>
                    <input type="file" name="images[]" class="form-control mb-1" accept="image/jpeg,image/png,image/webp" multiple>
                    <small class="text-muted d-block">Format: JPG, PNG, atau WEBP. Maksimal 2 MB per file.</small>
                </div>
            </div>
        </div>

        <!-- Kolom Kanan: Varian Produk & Stok -->
        <div class="col-12 col-lg-5">
            <div class="card border-0 shadow-sm rounded-3">
                <div class="card-header bg-white py-3 d-flex justify-content-between align-items-center border-bottom">
                    <h6 class="mb-0 fw-bold">Varian Produk & Stok</h6>
                    <button type="button" class="btn btn-sm btn-outline-rnz" onclick="addNewVariantRow()">
                        <i class="bi bi-plus-lg me-1"></i> Tambah Varian
                    </button>
                </div>
                <div class="card-body p-4">
                    <!-- Varian Lama -->
                    <label class="form-label small fw-bold text-secondary mb-2">Varian Aktif:</label>
                    <?php foreach ($variants as $var): ?>
                        <div class="border rounded p-3 mb-3 bg-white">
                            <input type="hidden" name="existing_variant_id[]" value="<?= $var['id'] ?>">
                            <div class="mb-2">
                                <label class="form-label small fw-semibold">Warna / Corak</label>
                                <input type="text" name="existing_variant_color[]" class="form-control form-control-sm" value="<?= esc($var['color']) ?>" required>
                            </div>
                            <div class="row g-2 mb-2">
                                <div class="col-6">
                                    <label class="form-label small fw-semibold">Ukuran</label>
                                    <input type="text" name="existing_variant_size[]" class="form-control form-control-sm" value="<?= esc($var['size'] ?? 'All Size') ?>">
                                </div>
                                <div class="col-6">
                                    <label class="form-label small fw-semibold">Stok Unit</label>
                                    <input type="number" name="existing_variant_stock[]" class="form-control form-control-sm" value="<?= $var['stock'] ?>" min="0" required>
                                </div>
                            </div>
                            <div>
                                <label class="form-label small fw-semibold">SKU / Kode</label>
                                <input type="text" name="existing_variant_sku[]" class="form-control form-control-sm" value="<?= esc($var['sku'] ?? '') ?>">
                            </div>
                        </div>
                    <?php endforeach; ?>

                    <!-- Wadah Varian Baru -->
                    <div id="newVariantContainer"></div>

                    <div class="mt-4">
                        <button type="submit" class="btn btn-rnz w-100 py-2">
                            <i class="bi bi-check-lg me-1"></i> Simpan Seluruh Perubahan
                        </button>
                    </div>
                </div>
            </div>
        </div>
    </div>
</form>

<?php if (!empty($images)): ?>
    <?php foreach ($images as $img): ?>
        <form id="deleteImgForm<?= $img['id'] ?>" action="/admin/products/delete-image/<?= $img['id'] ?>" method="POST" class="d-none">
            <?= csrf_field() ?>
            <button type="submit" class="btn btn-sm btn-danger position-absolute top-0 end-0 py-0 px-1 m-1" title="Hapus foto" onsubmit="return rnzConfirm('Hapus foto ini?', this)">
                <i class="bi bi-trash"></i>
            </button>
        </form>
    <?php endforeach; ?>
<?php endif; ?>

<script>
    function addNewVariantRow() {
        const container = document.getElementById('newVariantContainer');
        const row = document.createElement('div');
        row.className = 'border rounded p-3 mb-3 bg-light position-relative';
        row.innerHTML = `
            <button type="button" class="btn btn-sm btn-danger position-absolute top-0 end-0 m-2 py-0 px-2" onclick="this.parentElement.remove()">×</button>
            <div class="mb-2 pe-4">
                <label class="form-label small fw-semibold">Warna Baru <span class="text-danger">*</span></label>
                <input type="text" name="new_variant_color[]" class="form-control form-control-sm" placeholder="Contoh: Lavender" required>
            </div>
            <div class="row g-2 mb-2">
                <div class="col-6">
                    <label class="form-label small fw-semibold">Ukuran</label>
                    <input type="text" name="new_variant_size[]" class="form-control form-control-sm" value="All Size">
                </div>
                <div class="col-6">
                    <label class="form-label small fw-semibold">Stok Awal <span class="text-danger">*</span></label>
                    <input type="number" name="new_variant_stock[]" class="form-control form-control-sm" value="10" min="0" required>
                </div>
            </div>
            <div>
                <label class="form-label small fw-semibold">SKU (Opsional)</label>
                <input type="text" name="new_variant_sku[]" class="form-control form-control-sm" placeholder="Contoh: PASH-LAV-03">
            </div>
        `;
        container.appendChild(row);
    }
</script>
<?= $this->endSection() ?>
