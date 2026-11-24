<?= $this->extend('admin/layouts/main') ?>

<?= $this->section('content') ?>
<div class="row g-3 mb-4">
    <!-- Card 1: Omzet -->
    <div class="col-12 col-sm-6 col-xl-3">
        <div class="card card-stat p-3 bg-white">
            <div class="d-flex align-items-center justify-content-between">
                <div>
                    <span class="text-muted small fw-medium">Omzet Bulan Ini</span>
                    <h4 class="fw-bold mt-1 mb-0 text-dark">Rp <?= number_format($monthlyRevenue, 0, ',', '.') ?></h4>
                </div>
                <div class="stat-icon bg-success-subtle text-success">
                    <i class="bi bi-wallet2"></i>
                </div>
            </div>
        </div>
    </div>

    <!-- Card 2: Perlu Verifikasi -->
    <div class="col-12 col-sm-6 col-xl-3">
        <div class="card card-stat p-3 bg-white">
            <div class="d-flex align-items-center justify-content-between">
                <div>
                    <span class="text-muted small fw-medium">Perlu Verifikasi</span>
                    <h4 class="fw-bold mt-1 mb-0 text-warning"><?= $pendingVerificationCount ?></h4>
                </div>
                <div class="stat-icon bg-warning-subtle text-warning">
                    <i class="bi bi-hourglass-split"></i>
                </div>
            </div>
        </div>
    </div>

    <!-- Card 3: Sedang Diproses -->
    <div class="col-12 col-sm-6 col-xl-3">
        <div class="card card-stat p-3 bg-white">
            <div class="d-flex align-items-center justify-content-between">
                <div>
                    <span class="text-muted small fw-medium">Perlu Dikirim</span>
                    <h4 class="fw-bold mt-1 mb-0 text-primary"><?= $processingCount ?></h4>
                </div>
                <div class="stat-icon bg-primary-subtle text-primary">
                    <i class="bi bi-box-seam"></i>
                </div>
            </div>
        </div>
    </div>

    <!-- Card 4: Stok Menipis -->
    <div class="col-12 col-sm-6 col-xl-3">
        <div class="card card-stat p-3 bg-white">
            <div class="d-flex align-items-center justify-content-between">
                <div>
                    <span class="text-muted small fw-medium">Stok Tipis (≤ 3)</span>
                    <h4 class="fw-bold mt-1 mb-0 text-danger"><?= $lowStockCount ?></h4>
                </div>
                <div class="stat-icon bg-danger-subtle text-danger">
                    <i class="bi bi-exclamation-triangle"></i>
                </div>
            </div>
        </div>
    </div>
</div>

<div class="row g-4">
    <!-- Tabel Pesanan Terbaru -->
    <div class="col-12 col-xl-8">
        <div class="card border-0 shadow-sm rounded-3">
            <div class="card-header bg-white py-3 d-flex justify-content-between align-items-center border-bottom">
                <h6 class="mb-0 fw-bold"><i class="bi bi-clock-history me-2"></i>Pesanan Masuk Terbaru</h6>
                <a href="/admin/orders" class="btn btn-sm btn-outline-secondary">Lihat Semua</a>
            </div>
            <div class="card-body p-0">
                <div class="table-responsive">
                    <table class="table table-hover align-middle mb-0">
                        <thead class="table-light">
                            <tr>
                                <th class="ps-3">No. Pesanan</th>
                                <th>Pelanggan</th>
                                <th>Total</th>
                                <th>Status</th>
                                <th class="text-end pe-3">Aksi</th>
                            </tr>
                        </thead>
                        <tbody>
                            <?php if (empty($recentOrders)): ?>
                                <tr>
                                    <td colspan="5" class="text-center py-4 text-muted">Belum ada pesanan terbaru.</td>
                                </tr>
                            <?php else: ?>
                                <?php foreach ($recentOrders as $order): ?>
                                    <tr>
                                        <td class="ps-3 fw-semibold text-dark"><?= esc($order['order_no']) ?></td>
                                        <td><?= esc($order['customer_name']) ?></td>
                                        <td>Rp <?= number_format($order['total'], 0, ',', '.') ?></td>
                                        <td>
                                            <?php
                                                $badgeClass = 'badge-verifying';
                                                $statusText = $order['status'];
                                                if ($order['status'] === 'waiting_payment') { $badgeClass = 'bg-secondary text-white'; $statusText = 'Menunggu Bayar'; }
                                                elseif ($order['status'] === 'verifying_payment') { $badgeClass = 'badge-verifying'; $statusText = 'Verifikasi Bukti'; }
                                                elseif ($order['status'] === 'processing') { $badgeClass = 'badge-processing'; $statusText = 'Diproses'; }
                                                elseif ($order['status'] === 'shipped') { $badgeClass = 'badge-shipped'; $statusText = 'Dikirim'; }
                                                elseif ($order['status'] === 'completed') { $badgeClass = 'badge-completed'; $statusText = 'Selesai'; }
                                                elseif ($order['status'] === 'cancelled') { $badgeClass = 'badge-cancelled'; $statusText = 'Dibatalkan'; }
                                            ?>
                                            <span class="badge <?= $badgeClass ?> px-2 py-1 rounded-pill small"><?= $statusText ?></span>
                                        </td>
                                        <td class="text-end pe-3">
                                            <a href="/admin/orders/<?= $order['id'] ?>" class="btn btn-sm btn-light border">Detail</a>
                                        </td>
                                    </tr>
                                <?php endforeach; ?>
                            <?php endif; ?>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </div>

    <!-- Tabel Peringatan Stok Menipis -->
    <div class="col-12 col-xl-4">
        <div class="card border-0 shadow-sm rounded-3">
            <div class="card-header bg-white py-3 border-bottom">
                <h6 class="mb-0 fw-bold text-danger"><i class="bi bi-bell-fill me-2"></i>Peringatan Stok Tipis</h6>
            </div>
            <div class="card-body p-0">
                <div class="table-responsive">
                    <table class="table table-hover align-middle mb-0">
                        <thead class="table-light">
                            <tr>
                                <th class="ps-3">Produk & Varian</th>
                                <th class="text-center">Sisa</th>
                                <th class="text-end pe-3">Aksi</th>
                            </tr>
                        </thead>
                        <tbody>
                            <?php if (empty($lowStockVariants)): ?>
                                <tr>
                                    <td colspan="3" class="text-center py-4 text-muted">Seluruh stok varian aman ( > 3).</td>
                                </tr>
                            <?php else: ?>
                                <?php foreach ($lowStockVariants as $var): ?>
                                    <tr>
                                        <td class="ps-3">
                                            <div class="fw-semibold text-dark small"><?= esc($var['product_name']) ?></div>
                                            <span class="text-muted small"><?= esc($var['color']) ?> (<?= esc($var['size']) ?>)</span>
                                        </td>
                                        <td class="text-center">
                                            <span class="badge bg-danger text-white rounded-pill px-2"><?= $var['stock'] ?></span>
                                        </td>
                                        <td class="text-end pe-3">
                                            <a href="/admin/stock" class="btn btn-sm btn-outline-primary py-0">Tambah</a>
                                        </td>
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
