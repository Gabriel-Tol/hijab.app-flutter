<?= $this->extend('admin/layouts/main') ?>

<?= $this->section('content') ?>
<div class="d-flex flex-wrap justify-content-between align-items-center gap-3 mb-4">
    <div>
        <h5 class="fw-bold mb-1">Laporan Penjualan</h5>
        <p class="text-muted small mb-0">Rekap transaksi selesai dan cetak laporan resmi dalam format PDF.</p>
    </div>
    <a href="/admin/reports/export-pdf?start_date=<?= esc($startDate) ?>&end_date=<?= esc($endDate) ?>" class="btn btn-danger" target="_blank">
        <i class="bi bi-file-earmark-pdf me-1"></i> Unduh Laporan PDF
    </a>
</div>

<!-- Filter Rentang Tanggal -->
<div class="card border-0 shadow-sm rounded-3 mb-4">
    <div class="card-body p-3">
        <form action="/admin/reports" method="GET" class="row g-2 align-items-center">
            <div class="col-12 col-sm-4">
                <label class="form-label small fw-semibold text-secondary">Tanggal Mulai</label>
                <input type="date" name="start_date" class="form-control form-control-sm" value="<?= esc($startDate) ?>" required>
            </div>
            <div class="col-12 col-sm-4">
                <label class="form-label small fw-semibold text-secondary">Tanggal Akhir</label>
                <input type="date" name="end_date" class="form-control form-control-sm" value="<?= esc($endDate) ?>" required>
            </div>
            <div class="col-12 col-sm-4 d-flex align-items-end">
                <button type="submit" class="btn btn-sm btn-secondary w-100 py-2">
                    <i class="bi bi-filter me-1"></i> Terapkan Periode
                </button>
            </div>
        </form>
    </div>
</div>

<!-- Kartu Ringkasan -->
<div class="row g-3 mb-4">
    <div class="col-12 col-md-6">
        <div class="card card-stat p-3 bg-white">
            <span class="text-muted small fw-medium">Total Omzet Transaksi</span>
            <h4 class="fw-bold mt-1 mb-0 text-success">Rp <?= number_format($totalRevenue, 0, ',', '.') ?></h4>
            <small class="text-muted mt-1">Periode: <?= date('d M Y', strtotime($startDate)) ?> s/d <?= date('d M Y', strtotime($endDate)) ?></small>
        </div>
    </div>
    <div class="col-12 col-md-6">
        <div class="card card-stat p-3 bg-white">
            <span class="text-muted small fw-medium">Jumlah Transaksi Berhasil</span>
            <h4 class="fw-bold mt-1 mb-0 text-dark"><?= $orderCount ?> Pesanan</h4>
            <small class="text-muted mt-1">Status: Diproses, Dikirim, atau Selesai</small>
        </div>
    </div>
</div>

<!-- Tabel Rincian Transaksi -->
<div class="card border-0 shadow-sm rounded-3">
    <div class="card-header bg-white py-3 border-bottom">
        <h6 class="mb-0 fw-bold"><i class="bi bi-list-check me-2"></i>Rincian Pesanan Masuk (<?= count($orders) ?> Data)</h6>
    </div>
    <div class="card-body p-0">
        <div class="table-responsive">
            <table class="table table-hover align-middle mb-0">
                <thead class="table-light small">
                    <tr>
                        <th class="ps-3">No. Pesanan</th>
                        <th>Tanggal</th>
                        <th>Nama Pelanggan</th>
                        <th>Subtotal</th>
                        <th>Ongkir</th>
                        <th>Total</th>
                        <th>Status</th>
                        <th class="text-end pe-3">Aksi</th>
                    </tr>
                </thead>
                <tbody>
                    <?php if (empty($orders)): ?>
                        <tr>
                            <td colspan="8" class="text-center py-5 text-muted">
                                Tidak ada transaksi berhasil pada rentang tanggal yang dipilih.
                            </td>
                        </tr>
                    <?php else: ?>
                        <?php foreach ($orders as $o): ?>
                            <tr>
                                <td class="ps-3 fw-bold text-dark"><?= esc($o['order_no']) ?></td>
                                <td><?= date('d/m/Y H:i', strtotime($o['created_at'])) ?></td>
                                <td><?= esc($o['customer_name']) ?></td>
                                <td>Rp <?= number_format($o['subtotal'], 0, ',', '.') ?></td>
                                <td>Rp <?= number_format($o['shipping_cost'], 0, ',', '.') ?></td>
                                <td class="fw-bold text-success">Rp <?= number_format($o['total'], 0, ',', '.') ?></td>
                                <td>
                                    <span class="badge bg-success-subtle text-success small"><?= strtoupper($o['status']) ?></span>
                                </td>
                                <td class="text-end pe-3">
                                    <a href="/admin/orders/<?= $o['id'] ?>" class="btn btn-sm btn-light border py-0 px-2">Detail</a>
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
