<?= $this->extend('admin/layouts/main') ?>

<?= $this->section('content') ?>
<div class="d-flex flex-wrap justify-content-between align-items-center gap-3 mb-4">
    <div>
        <h5 class="fw-bold mb-1">Katalog Produk & Varian</h5>
        <p class="text-muted small mb-0">Kelola daftar hijab, harga, stok varian warna/ukuran, dan galeri foto.</p>
    </div>
    <a href="/admin/products/create" class="btn btn-rnz">
        <i class="bi bi-plus-lg me-1"></i> Tambah Produk Baru
    </a>
</div>

<!-- Filter & Pencarian -->
<div class="card border-0 shadow-sm rounded-3 mb-4">
    <div class="card-body p-3">
        <form action="/admin/products" method="GET" class="row g-2 align-items-center">
            <div class="col-12 col-md-5">
                <div class="input-group">
                    <span class="input-group-text bg-white"><i class="bi bi-search text-muted"></i></span>
                    <input type="text" name="search" class="form-control border-start-0" placeholder="Cari nama produk hijab..." value="<?= esc($keyword ?? '') ?>">
                </div>
            </div>
            <div class="col-12 col-md-4">
                <select name="category_id" class="form-select">
                    <option value="">Semua Kategori</option>
                    <?php foreach ($categories as $cat): ?>
                        <option value="<?= $cat['id'] ?>" <?= ($categoryId == $cat['id']) ? 'selected' : '' ?>>
                            <?= esc($cat['name']) ?>
                        </option>
                    <?php endforeach; ?>
                </select>
            </div>
            <div class="col-12 col-md-3 d-flex gap-2">
                <button type="submit" class="btn btn-secondary w-100">Filter</button>
                <?php if (!empty($keyword) || !empty($categoryId)): ?>
                    <a href="/admin/products" class="btn btn-outline-secondary">Reset</a>
                <?php endif; ?>
            </div>
        </form>
    </div>
</div>

<!-- Tabel Produk -->
<div class="card border-0 shadow-sm rounded-3">
    <div class="card-body p-0">
        <div class="table-responsive">
            <table class="table table-hover align-middle mb-0">
                <thead class="table-light">
                    <tr>
                        <th class="ps-3" style="width: 80px;">Foto</th>
                        <th>Nama Produk</th>
                        <th>Kategori</th>
                        <th>Harga</th>
                        <th class="text-center">Total Stok</th>
                        <th>Status</th>
                        <th class="text-end pe-3">Aksi</th>
                    </tr>
                </thead>
                <tbody>
                    <?php if (empty($products)): ?>
                        <tr>
                            <td colspan="7" class="text-center py-5 text-muted">
                                <i class="bi bi-box-seam fs-1 d-block mb-2 text-secondary"></i>
                                Tidak ada produk yang ditemukan.
                            </td>
                        </tr>
                    <?php else: ?>
                        <?php foreach ($products as $prod): ?>
                            <tr>
                                <td class="ps-3">
                                    <?php if (!empty($prod['thumbnail'])): ?>
                                        <img src="/<?= esc($prod['thumbnail']) ?>" alt="<?= esc($prod['name']) ?>" class="rounded" style="width: 50px; height: 50px; object-fit: cover;">
                                    <?php else: ?>
                                        <div class="bg-light rounded d-flex align-items-center justify-content-center text-muted" style="width: 50px; height: 50px;">
                                            <i class="bi bi-image"></i>
                                        </div>
                                    <?php endif; ?>
                                </td>
                                <td>
                                    <div class="fw-bold text-dark"><?= esc($prod['name']) ?></div>
                                    <small class="text-muted"><code>/<?= esc($prod['slug']) ?></code></small>
                                </td>
                                <td>
                                    <span class="badge bg-light text-dark border"><?= esc($prod['category_name'] ?? 'Tanpa Kategori') ?></span>
                                </td>
                                <td class="fw-semibold">Rp <?= number_format($prod['price'], 0, ',', '.') ?></td>
                                <td class="text-center">
                                    <?php if ($prod['total_stock'] <= 0): ?>
                                        <span class="badge bg-danger">Habis</span>
                                    <?php elseif ($prod['total_stock'] <= 3): ?>
                                        <span class="badge bg-warning text-dark"><?= $prod['total_stock'] ?> Unit</span>
                                    <?php else: ?>
                                        <span class="badge bg-success-subtle text-success"><?= $prod['total_stock'] ?> Unit</span>
                                    <?php endif; ?>
                                </td>
                                <td>
                                    <?php if ($prod['is_active']): ?>
                                        <span class="badge bg-success-subtle text-success">Aktif</span>
                                    <?php else: ?>
                                        <span class="badge bg-secondary-subtle text-secondary">Nonaktif</span>
                                    <?php endif; ?>
                                </td>
                                <td class="text-end pe-3">
                                    <a href="/admin/products/edit/<?= $prod['id'] ?>" class="btn btn-sm btn-outline-secondary me-1" title="Ubah">
                                        <i class="bi bi-pencil"></i>
                                    </a>
                                    <a href="/admin/products/delete/<?= $prod['id'] ?>" class="btn btn-sm btn-outline-danger" title="Hapus" onclick="return confirm('Apakah Anda yakin ingin menghapus produk ini?')">
                                        <i class="bi bi-trash"></i>
                                    </a>
                                </td>
                            </tr>
                        <?php endforeach; ?>
                    <?php endif; ?>
                </tbody>
            </table>
        </div>
    </div>
</div>
<?= $this->endSection() ?>
