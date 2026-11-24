<?= $this->extend('admin/layouts/main') ?>

<?= $this->section('content') ?>
<div class="d-flex justify-content-between align-items-center mb-4">
    <div>
        <h5 class="fw-bold font-serif mb-1">Kategori Produk</h5>
        <p class="text-muted small mb-0">Kelola kelompok produk hijab, busana, dan aksesori.</p>
    </div>
    <button class="btn btn-rnz" data-bs-toggle="modal" data-bs-target="#modalAddCategory">
        <i class="bi bi-plus-lg me-1"></i> Tambah Kategori
    </button>
</div>

<div class="card border-0 shadow-sm rounded-3">
    <div class="card-body p-0">
        <div class="table-responsive">
            <table class="table table-hover align-middle mb-0">
                <thead class="table-light">
                    <tr>
                        <th class="ps-3" style="width: 60px;">#</th>
                        <th>Nama Kategori</th>
                        <th>Slug URL</th>
                        <th class="text-center">Jumlah Produk</th>
                        <th>Status</th>
                        <th class="text-end pe-3">Aksi</th>
                    </tr>
                </thead>
                <tbody>
                    <?php if (empty($categories)): ?>
                        <tr>
                            <td colspan="6" class="text-center py-4 text-muted">Belum ada kategori produk.</td>
                        </tr>
                    <?php else: ?>
                        <?php foreach ($categories as $index => $cat): ?>
                            <tr>
                                <td class="ps-3 text-muted"><?= $index + 1 ?></td>
                                <td class="fw-semibold text-dark"><?= esc($cat['name']) ?></td>
                                <td><code>/<?= esc($cat['slug']) ?></code></td>
                                <td class="text-center">
                                    <span class="badge bg-light text-dark border px-2"><?= $cat['product_count'] ?> Produk</span>
                                </td>
                                <td>
                                    <?php if ($cat['is_active']): ?>
                                        <span class="badge badge-completed px-2 py-1 rounded-pill">Aktif</span>
                                    <?php else: ?>
                                        <span class="badge badge-waiting px-2 py-1 rounded-pill">Nonaktif</span>
                                    <?php endif; ?>
                                </td>
                                <td class="text-end pe-3">
                                    <button class="btn btn-sm btn-outline-rnz me-1 py-1 px-2" data-bs-toggle="modal" data-bs-target="#modalEditCategory<?= $cat['id'] ?>">
                                        <i class="bi bi-pencil"></i>
                                    </button>
                                    <a href="/admin/categories/delete/<?= $cat['id'] ?>" class="btn btn-sm btn-outline-terracotta py-1 px-2" onclick="return confirm('Apakah Anda yakin ingin menghapus kategori ini?')">
                                        <i class="bi bi-trash"></i>
                                    </a>
                                </td>
                            </tr>

                            <!-- Modal Edit Kategori -->
                            <div class="modal fade" id="modalEditCategory<?= $cat['id'] ?>" tabindex="-1">
                                <div class="modal-dialog">
                                    <div class="modal-content">
                                        <form action="/admin/categories/update/<?= $cat['id'] ?>" method="POST">
                                            <?= csrf_field() ?>
                                            <div class="modal-header">
                                                <h6 class="modal-title fw-bold">Ubah Kategori</h6>
                                                <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                                            </div>
                                            <div class="modal-body">
                                                <div class="mb-3">
                                                    <label class="form-label small fw-semibold">Nama Kategori</label>
                                                    <input type="text" name="name" class="form-control" value="<?= esc($cat['name']) ?>" required>
                                                </div>
                                                <div class="form-check form-switch">
                                                    <input class="form-check-input" type="checkbox" name="is_active" value="1" id="activeSwitch<?= $cat['id'] ?>" <?= $cat['is_active'] ? 'checked' : '' ?>>
                                                    <label class="form-check-label small" for="activeSwitch<?= $cat['id'] ?>">Tampilkan di aplikasi pelanggan</label>
                                                </div>
                                            </div>
                                            <div class="modal-footer">
                                                <button type="button" class="btn btn-sm btn-secondary" data-bs-dismiss="modal">Batal</button>
                                                <button type="submit" class="btn btn-sm btn-rnz">Simpan Perubahan</button>
                                            </div>
                                        </form>
                                    </div>
                                </div>
                            </div>
                        <?php endforeach; ?>
                    <?php endif; ?>
                </tbody>
            </table>
        </div>
    </div>
</div>

<!-- Modal Tambah Kategori -->
<div class="modal fade" id="modalAddCategory" tabindex="-1">
    <div class="modal-dialog">
        <div class="modal-content">
            <form action="/admin/categories" method="POST">
                <?= csrf_field() ?>
                <div class="modal-header">
                    <h6 class="modal-title fw-bold">Tambah Kategori Baru</h6>
                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                </div>
                <div class="modal-body">
                    <div class="mb-3">
                        <label class="form-label small fw-semibold">Nama Kategori</label>
                        <input type="text" name="name" class="form-control" placeholder="Contoh: Pashmina Plisket" required>
                    </div>
                    <div class="form-check form-switch">
                        <input class="form-check-input" type="checkbox" name="is_active" value="1" id="activeSwitchNew" checked>
                        <label class="form-check-label small" for="activeSwitchNew">Tampilkan di aplikasi pelanggan</label>
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-sm btn-secondary" data-bs-dismiss="modal">Batal</button>
                    <button type="submit" class="btn btn-sm btn-rnz">Tambah Kategori</button>
                </div>
            </form>
        </div>
    </div>
</div>
<?= $this->endSection() ?>
