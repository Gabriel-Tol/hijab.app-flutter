<?= $this->extend('admin/layouts/main') ?>

<?= $this->section('content') ?>
<div class="row g-3 mb-4">
    <!-- Card 1: Omzet -->
    <div class="col-12 col-sm-6 col-xl-3">
        <div class="card card-stat p-3 bg-white">
            <div class="d-flex align-items-center justify-content-between">
                <div>
                    <span class="text-muted small fw-semibold">Omzet Bulan Ini</span>
                    <h4 class="fw-bold mt-1 mb-0 font-serif" style="color: var(--rnz-forest);">Rp <?= number_format($monthlyRevenue, 0, ',', '.') ?></h4>
                </div>
                <div class="stat-icon" style="background-color: var(--rnz-forest-light); color: var(--rnz-forest);">
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
                    <span class="text-muted small fw-semibold">Perlu Verifikasi</span>
                    <h4 class="fw-bold mt-1 mb-0 font-serif" style="color: var(--rnz-warning);"><?= $pendingVerificationCount ?></h4>
                </div>
                <div class="stat-icon" style="background-color: var(--rnz-warning-bg); color: var(--rnz-warning);">
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
                    <span class="text-muted small fw-semibold">Perlu Dikirim</span>
                    <h4 class="fw-bold mt-1 mb-0 font-serif" style="color: var(--rnz-info);"><?= $processingCount ?></h4>
                </div>
                <div class="stat-icon" style="background-color: var(--rnz-info-bg); color: var(--rnz-info);">
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
                    <span class="text-muted small fw-semibold">Stok Tipis (≤ 3)</span>
                    <h4 class="fw-bold mt-1 mb-0 font-serif" style="color: var(--rnz-danger);"><?= $lowStockCount ?></h4>
                </div>
                <div class="stat-icon" style="background-color: var(--rnz-danger-bg); color: var(--rnz-danger);">
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
                <h6 class="mb-0 fw-bold font-serif"><i class="bi bi-clock-history me-2" style="color: var(--rnz-terracotta);"></i>Pesanan Masuk Terbaru</h6>
                <a href="/admin/orders" class="btn btn-sm btn-outline-rnz">Lihat Semua</a>
            </div>
            <div class="card-body p-0">
                <div class="table-responsive">
                    <table class="table table-hover align-middle mb-0">
                        <thead>
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
                                        <td class="fw-bold" style="color: var(--rnz-forest);">Rp <?= number_format($order['total'], 0, ',', '.') ?></td>
                                        <td>
                                            <?php
                                                $badgeClass = 'badge-verifying';
                                                $statusText = $order['status'];
                                                if ($order['status'] === 'waiting_payment') { $badgeClass = 'badge-waiting'; $statusText = 'Menunggu Bayar'; }
                                                elseif ($order['status'] === 'verifying_payment') { $badgeClass = 'badge-verifying'; $statusText = 'Verifikasi Bukti'; }
                                                elseif ($order['status'] === 'processing') { $badgeClass = 'badge-processing'; $statusText = 'Diproses'; }
                                                elseif ($order['status'] === 'shipped') { $badgeClass = 'badge-shipped'; $statusText = 'Dikirim'; }
                                                elseif ($order['status'] === 'completed') { $badgeClass = 'badge-completed'; $statusText = 'Selesai'; }
                                                elseif ($order['status'] === 'cancelled') { $badgeClass = 'badge-cancelled'; $statusText = 'Dibatalkan'; }
                                            ?>
                                            <span class="badge <?= $badgeClass ?> px-2 py-1 rounded-pill small"><?= $statusText ?></span>
                                        </td>
                                        <td class="text-end pe-3">
                                            <a href="/admin/orders/<?= $order['id'] ?>" class="btn btn-sm btn-outline-rnz py-0 px-2">Detail</a>
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
                <h6 class="mb-0 fw-bold font-serif" style="color: var(--rnz-danger);"><i class="bi bi-bell-fill me-2"></i>Peringatan Stok Tipis</h6>
            </div>
            <div class="card-body p-0">
                <div class="table-responsive">
                    <table class="table table-hover align-middle mb-0">
                        <thead>
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
                                            <span class="badge rounded-pill px-2" style="background-color: var(--rnz-danger-bg); color: var(--rnz-danger); border: 1px solid var(--rnz-danger-border); font-weight: 700;"><?= $var['stock'] ?></span>
                                        </td>
                                        <td class="text-end pe-3">
                                            <a href="/admin/stock" class="btn btn-sm btn-outline-terracotta py-0 px-2">Tambah</a>
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
