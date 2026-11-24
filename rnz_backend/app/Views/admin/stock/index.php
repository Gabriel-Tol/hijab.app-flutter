<?= $this->extend('admin/layouts/main') ?>

<?= $this->section('content') ?>
<div class="d-flex flex-wrap justify-content-between align-items-center gap-3 mb-4">
    <div>
        <h5 class="fw-bold mb-1">Stok & Stock Opname</h5>
        <p class="text-muted small mb-0">Pantau ketersediaan stok fisik per varian dan lakukan penyesuaian (opname) stok.</p>
    </div>
</div>

<div class="row g-4">
    <!-- Tabel Stok Varian -->
    <div class="col-12 col-xl-7">
        <div class="card border-0 shadow-sm rounded-3">
            <div class="card-header bg-white py-3 border-bottom">
                <h6 class="mb-0 fw-bold"><i class="bi bi-boxes me-2"></i>Daftar Stok Produk Hijab</h6>
            </div>
            <div class="card-body p-0">
                <div class="table-responsive">
                    <table class="table table-hover align-middle mb-0">
                        <thead class="table-light">
                            <tr>
                                <th class="ps-3">Produk & Varian</th>
                                <th>Kategori</th>
                                <th class="text-center">Stok</th>
                                <th class="text-end pe-3">Aksi</th>
                            </tr>
                        </thead>
                        <tbody>
                            <?php if (empty($variants)): ?>
                                <tr>
                                    <td colspan="4" class="text-center py-4 text-muted">Belum ada varian produk.</td>
                                </tr>
                            <?php else: ?>
                                <?php foreach ($variants as $v): ?>
                                    <tr>
                                        <td class="ps-3">
                                            <div class="fw-bold text-dark"><?= esc($v['product_name']) ?></div>
                                            <small class="text-muted"><?= esc($v['color']) ?> (<?= esc($v['size']) ?>) <?= $v['sku'] ? '• ' . esc($v['sku']) : '' ?></small>
                                        </td>
                                        <td><span class="badge bg-light text-dark border"><?= esc($v['category_name']) ?></span></td>
                                        <td class="text-center">
                                            <?php if ($v['stock'] <= 0): ?>
                                                <span class="badge bg-danger rounded-pill px-2">Habis</span>
                                            <?php elseif ($v['stock'] <= 3): ?>
                                                <span class="badge bg-warning text-dark rounded-pill px-2"><?= $v['stock'] ?></span>
                                            <?php else: ?>
                                                <span class="badge bg-success-subtle text-success rounded-pill px-2"><?= $v['stock'] ?></span>
                                            <?php endif; ?>
                                        </td>
                                        <td class="text-end pe-3">
                                            <button class="btn btn-sm btn-outline-primary" data-bs-toggle="modal" data-bs-target="#modalOpname<?= $v['id'] ?>">
                                                <i class="bi bi-pencil-square me-1"></i> Sesuaikan
                                            </button>
                                        </td>
                                    </tr>

                                    <!-- Modal Opname -->
                                    <div class="modal fade" id="modalOpname<?= $v['id'] ?>" tabindex="-1">
                                        <div class="modal-dialog">
                                            <div class="modal-content">
                                                <form action="/admin/stock/adjust" method="POST">
                                                    <?= csrf_field() ?>
                                                    <input type="hidden" name="variant_id" value="<?= $v['id'] ?>">
                                                    <div class="modal-header">
                                                        <h6 class="modal-title fw-bold">Stock Opname: <?= esc($v['product_name']) ?></h6>
                                                        <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                                                    </div>
                                                    <div class="modal-body">
                                                        <div class="alert alert-light border small mb-3">
                                                            <strong>Varian:</strong> <?= esc($v['color']) ?> (<?= esc($v['size']) ?>)<br>
                                                            <strong>Stok Saat Ini di Sistem:</strong> <span class="badge bg-dark"><?= $v['stock'] ?> Unit</span>
                                                        </div>
                                                        <div class="mb-3">
                                                            <label class="form-label small fw-semibold">Perubahan Qty (+ Tambah / - Kurang) <span class="text-danger">*</span></label>
                                                            <input type="number" name="qty_change" class="form-control" placeholder="Contoh: 5 (tambah) atau -2 (rusak)" required>
                                                            <small class="text-muted">Masukkan nilai positif jika restock, atau negatif jika barang rusak/hilang.</small>
                                                        </div>
                                                        <div class="mb-3">
                                                            <label class="form-label small fw-semibold">Alasan Penyesuaian <span class="text-danger">*</span></label>
                                                            <input type="text" name="reason" class="form-control" placeholder="Contoh: Restock suplier baru / Barang cacat produksi" required>
                                                        </div>
                                                    </div>
                                                    <div class="modal-footer">
                                                        <button type="button" class="btn btn-sm btn-secondary" data-bs-dismiss="modal">Batal</button>
                                                        <button type="submit" class="btn btn-sm btn-rnz">Simpan Penyesuaian</button>
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
    </div>

    <!-- Riwayat Mutasi Stok -->
    <div class="col-12 col-xl-5">
        <div class="card border-0 shadow-sm rounded-3">
            <div class="card-header bg-white py-3 border-bottom">
                <h6 class="mb-0 fw-bold"><i class="bi bi-clock-history me-2"></i>20 Log Mutasi Terakhir</h6>
            </div>
            <div class="card-body p-0">
                <div class="table-responsive" style="max-height: 600px; overflow-y: auto;">
                    <table class="table table-hover align-middle mb-0 small">
                        <thead class="table-light">
                            <tr>
                                <th class="ps-3">Waktu</th>
                                <th>Item & Tipe</th>
                                <th class="text-center">Perubahan</th>
                                <th class="text-end pe-3">Sisa</th>
                            </tr>
                        </thead>
                        <tbody>
                            <?php if (empty($movements)): ?>
                                <tr>
                                    <td colspan="4" class="text-center py-4 text-muted">Belum ada riwayat mutasi stok.</td>
                                </tr>
                            <?php else: ?>
                                <?php foreach ($movements as $m): ?>
                                    <tr>
                                        <td class="ps-3 text-muted">
                                            <?= date('d/m H:i', strtotime($m['created_at'])) ?>
                                        </td>
                                        <td>
                                            <div class="fw-semibold text-dark"><?= esc($m['product_name']) ?></div>
                                            <span class="text-muted"><?= esc($m['color']) ?></span>
                                            <div class="text-secondary" style="font-size: 0.72rem;"><?= esc($m['reason']) ?></div>
                                        </td>
                                        <td class="text-center">
                                            <?php if ($m['qty_change'] > 0): ?>
                                                <span class="badge bg-success-subtle text-success">+<?= $m['qty_change'] ?></span>
                                            <?php else: ?>
                                                <span class="badge bg-danger-subtle text-danger"><?= $m['qty_change'] ?></span>
                                            <?php endif; ?>
                                        </td>
                                        <td class="text-end pe-3 fw-bold"><?= $m['stock_after'] ?></td>
                                    </tr>
                                <?php endforeach; ?>
                            <?php endif; ?>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </div>
</div>
<?= $this->endSection() ?>
