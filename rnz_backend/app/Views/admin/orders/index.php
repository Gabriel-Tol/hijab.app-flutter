<?= $this->extend('admin/layouts/main') ?>

<?= $this->section('content') ?>
<div class="d-flex flex-wrap justify-content-between align-items-center gap-3 mb-4">
    <div>
        <h5 class="fw-bold mb-1">Pesanan Masuk & Verifikasi</h5>
        <p class="text-muted small mb-0">Pantau transaksi belanja, periksa bukti transfer, dan input resi ekspedisi.</p>
    </div>
</div>

<!-- Tab Filter Status -->
<div class="card border-0 shadow-sm rounded-3 mb-4">
    <div class="card-body p-2">
        <ul class="nav nav-pills flex-column flex-sm-row gap-1">
            <li class="nav-item">
                <a class="nav-link <?= $statusTab === 'all' ? 'active' : '' ?> py-2 px-3 small" style="<?= $statusTab === 'all' ? 'background-color: var(--rnz-forest); color: #FFFFFF;' : 'color: var(--rnz-muted);' ?>" href="/admin/orders?status=all">
                    Semua <span class="badge ms-1" style="<?= $statusTab === 'all' ? 'background-color: rgba(255,255,255,0.25); color: #FFFFFF;' : 'background-color: var(--rnz-line); color: var(--rnz-ink);' ?>"><?= $counts['all'] ?></span>
                </a>
            </li>
            <li class="nav-item">
                <a class="nav-link <?= $statusTab === 'verifying_payment' ? 'active' : '' ?> py-2 px-3 small" style="<?= $statusTab === 'verifying_payment' ? 'background-color: var(--rnz-warning); color: #FFFFFF;' : 'color: var(--rnz-muted);' ?>" href="/admin/orders?status=verifying_payment">
                    <i class="bi bi-hourglass-split me-1"></i> Perlu Verifikasi
                    <?php if ($counts['verifying_payment'] > 0): ?>
                        <span class="badge ms-1" style="background-color: var(--rnz-danger); color: #FFFFFF;"><?= $counts['verifying_payment'] ?></span>
                    <?php endif; ?>
                </a>
            </li>
            <li class="nav-item">
                <a class="nav-link <?= $statusTab === 'processing' ? 'active' : '' ?> py-2 px-3 small" style="<?= $statusTab === 'processing' ? 'background-color: var(--rnz-info); color: #FFFFFF;' : 'color: var(--rnz-muted);' ?>" href="/admin/orders?status=processing">
                    <i class="bi bi-box-seam me-1"></i> Diproses <span class="badge ms-1" style="<?= $statusTab === 'processing' ? 'background-color: rgba(255,255,255,0.25); color: #FFFFFF;' : 'background-color: var(--rnz-line); color: var(--rnz-ink);' ?>"><?= $counts['processing'] ?></span>
                </a>
            </li>
            <li class="nav-item">
                <a class="nav-link <?= $statusTab === 'shipped' ? 'active' : '' ?> py-2 px-3 small" style="<?= $statusTab === 'shipped' ? 'background-color: #553C7B; color: #FFFFFF;' : 'color: var(--rnz-muted);' ?>" href="/admin/orders?status=shipped">
                    <i class="bi bi-truck me-1"></i> Dikirim <span class="badge ms-1" style="<?= $statusTab === 'shipped' ? 'background-color: rgba(255,255,255,0.25); color: #FFFFFF;' : 'background-color: var(--rnz-line); color: var(--rnz-ink);' ?>"><?= $counts['shipped'] ?></span>
                </a>
            </li>
            <li class="nav-item">
                <a class="nav-link <?= $statusTab === 'waiting_payment' ? 'active' : '' ?> py-2 px-3 small" style="<?= $statusTab === 'waiting_payment' ? 'background-color: var(--rnz-muted); color: #FFFFFF;' : 'color: var(--rnz-muted);' ?>" href="/admin/orders?status=waiting_payment">
                    Menunggu Bayar <span class="badge ms-1" style="<?= $statusTab === 'waiting_payment' ? 'background-color: rgba(255,255,255,0.25); color: #FFFFFF;' : 'background-color: var(--rnz-line); color: var(--rnz-ink);' ?>"><?= $counts['waiting_payment'] ?></span>
                </a>
            </li>
            <li class="nav-item">
                <a class="nav-link <?= $statusTab === 'completed' ? 'active' : '' ?> py-2 px-3 small" style="<?= $statusTab === 'completed' ? 'background-color: var(--rnz-success); color: #FFFFFF;' : 'color: var(--rnz-muted);' ?>" href="/admin/orders?status=completed">
                    Selesai <span class="badge ms-1" style="<?= $statusTab === 'completed' ? 'background-color: rgba(255,255,255,0.25); color: #FFFFFF;' : 'background-color: var(--rnz-line); color: var(--rnz-ink);' ?>"><?= $counts['completed'] ?></span>
                </a>
            </li>
            <li class="nav-item">
                <a class="nav-link <?= $statusTab === 'cancelled' ? 'active' : '' ?> py-2 px-3 small" style="<?= $statusTab === 'cancelled' ? 'background-color: var(--rnz-danger); color: #FFFFFF;' : 'color: var(--rnz-muted);' ?>" href="/admin/orders?status=cancelled">
                    Dibatalkan <span class="badge ms-1" style="<?= $statusTab === 'cancelled' ? 'background-color: rgba(255,255,255,0.25); color: #FFFFFF;' : 'background-color: var(--rnz-line); color: var(--rnz-ink);' ?>"><?= $counts['cancelled'] ?></span>
                </a>
            </li>
        </ul>
    </div>
</div>

<!-- Search Bar -->
<div class="card border-0 shadow-sm rounded-3 mb-4">
    <div class="card-body p-3">
        <form action="/admin/orders" method="GET" class="row g-2 align-items-center">
            <input type="hidden" name="status" value="<?= esc($statusTab) ?>">
            <div class="col-12 col-md-9">
                <div class="input-group">
                    <span class="input-group-text bg-white"><i class="bi bi-search text-muted"></i></span>
                    <input type="text" name="search" class="form-control border-start-0" placeholder="Cari nomor pesanan atau nama pelanggan..." value="<?= esc($keyword ?? '') ?>">
                </div>
            </div>
            <div class="col-12 col-md-3 d-flex gap-2">
                <button type="submit" class="btn btn-rnz w-100">Cari</button>
                <?php if (!empty($keyword)): ?>
                    <a href="/admin/orders?status=<?= esc($statusTab) ?>" class="btn btn-outline-secondary">Reset</a>
                <?php endif; ?>
            </div>
        </form>
    </div>
</div>

<!-- Tabel Pesanan -->
<div class="card border-0 shadow-sm rounded-3">
    <div class="card-body p-0">
        <div class="table-responsive">
            <table class="table table-hover align-middle mb-0">
                <thead class="table-light">
                    <tr>
                        <th class="ps-3">No. Pesanan</th>
                        <th>Waktu Pesan</th>
                        <th>Pelanggan</th>
                        <th>Nominal Total</th>
                        <th>Status</th>
                        <th class="text-end pe-3">Aksi</th>
                    </tr>
                </thead>
                <tbody>
                    <?php if (empty($orders)): ?>
                        <tr>
                            <td colspan="6" class="text-center py-5 text-muted">
                                <i class="bi bi-receipt fs-1 d-block mb-2 text-secondary"></i>
                                Tidak ada data pesanan pada kriteria ini.
                            </td>
                        </tr>
                    <?php else: ?>
                        <?php foreach ($orders as $order): ?>
                            <tr>
                                <td class="ps-3">
                                    <a href="/admin/orders/<?= $order['id'] ?>" class="fw-bold text-dark text-decoration-none">
                                        <?= esc($order['order_no']) ?>
                                    </a>
                                </td>
                                <td>
                                    <small class="text-muted d-block"><?= date('d M Y', strtotime($order['created_at'])) ?></small>
                                    <small class="text-secondary"><?= date('H:i', strtotime($order['created_at'])) ?> WIB</small>
                                </td>
                                <td>
                                    <div class="fw-semibold text-dark"><?= esc($order['customer_name']) ?></div>
                                    <small class="text-muted"><?= esc($order['customer_phone']) ?></small>
                                </td>
                                <td class="fw-bold text-dark">
                                    Rp <?= number_format($order['total'], 0, ',', '.') ?>
                                </td>
                                <td>
                                    <?php
                                        $badgeClass = 'bg-secondary text-white';
                                        $statusText = $order['status'];
                                        if ($order['status'] === 'waiting_payment') { $badgeClass = 'bg-secondary text-white'; $statusText = 'Menunggu Pembayaran'; }
                                        elseif ($order['status'] === 'verifying_payment') { $badgeClass = 'badge-verifying fw-bold'; $statusText = 'Perlu Verifikasi'; }
                                        elseif ($order['status'] === 'processing') { $badgeClass = 'badge-processing fw-bold'; $statusText = 'Sedang Diproses'; }
                                        elseif ($order['status'] === 'shipped') { $badgeClass = 'badge-shipped fw-bold'; $statusText = 'Dalam Pengiriman'; }
                                        elseif ($order['status'] === 'completed') { $badgeClass = 'badge-completed fw-bold'; $statusText = 'Selesai'; }
                                        elseif ($order['status'] === 'cancelled') { $badgeClass = 'badge-cancelled fw-bold'; $statusText = 'Dibatalkan'; }
                                    ?>
                                    <span class="badge <?= $badgeClass ?> px-2 py-1 rounded-pill small"><?= $statusText ?></span>
                                </td>
                                <td class="text-end pe-3">
                                    <a href="/admin/orders/<?= $order['id'] ?>" class="btn btn-sm btn-rnz">
                                        Periksa <i class="bi bi-chevron-right ms-1"></i>
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
