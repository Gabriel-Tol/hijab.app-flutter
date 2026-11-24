<?= $this->extend('admin/layouts/main') ?>

<?= $this->section('content') ?>
<div class="mb-4">
    <a href="/admin/orders" class="text-decoration-none text-muted small"><i class="bi bi-arrow-left me-1"></i> Kembali ke Daftar Pesanan</a>
    <div class="d-flex flex-wrap justify-content-between align-items-center gap-2 mt-2">
        <div>
            <h5 class="fw-bold mb-0">Pesanan #<?= esc($order['order_no']) ?></h5>
            <small class="text-muted">Dibuat pada <?= date('d M Y, H:i', strtotime($order['created_at'])) ?> WIB</small>
        </div>
        <div>
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
            <span class="badge <?= $badgeClass ?> px-3 py-2 fs-6 rounded-pill"><?= $statusText ?></span>
        </div>
    </div>
</div>

<div class="row g-4">
    <!-- Kolom Kiri: Verifikasi Pembayaran & Pengiriman -->
    <div class="col-12 col-lg-5">
        <!-- 1. Bukti Pembayaran -->
        <div class="card border-0 shadow-sm rounded-3 mb-4">
            <div class="card-header bg-white py-3 border-bottom">
                <h6 class="mb-0 fw-bold"><i class="bi bi-credit-card me-2"></i>Verifikasi Bukti Transfer</h6>
            </div>
            <div class="card-body p-4 text-center">
                <?php if (empty($proofs)): ?>
                    <div class="py-4 text-muted">
                        <i class="bi bi-image fs-1 d-block mb-2 text-secondary"></i>
                        Pelanggan belum mengunggah bukti pembayaran.
                    </div>
                <?php else: ?>
                    <?php $latestProof = $proofs[0]; ?>
                    <div class="mb-3">
                        <img src="/<?= esc($latestProof['file_path']) ?>" alt="Bukti Transfer" class="img-thumbnail rounded shadow-sm" style="max-height: 260px; cursor: pointer;" data-bs-toggle="modal" data-bs-target="#modalProofZoom">
                        <div class="small text-muted mt-1"><i class="bi bi-zoom-in me-1"></i>Klik gambar untuk memperbesar</div>
                    </div>

                    <div class="bg-light rounded p-3 text-start small mb-3">
                        <div class="d-flex justify-content-between mb-1">
                            <span class="text-muted">Nominal Tagihan:</span>
                            <span class="fw-bold text-dark">Rp <?= number_format($order['total'], 0, ',', '.') ?></span>
                        </div>
                        <div class="d-flex justify-content-between mb-1">
                            <span class="text-muted">Waktu Unggah:</span>
                            <span class="text-dark"><?= date('d M Y, H:i', strtotime($latestProof['created_at'])) ?> WIB</span>
                        </div>
                        <div class="d-flex justify-content-between">
                            <span class="text-muted">Status Bukti:</span>
                            <span class="badge <?= $latestProof['status'] === 'approved' ? 'bg-success' : ($latestProof['status'] === 'rejected' ? 'bg-danger' : 'bg-warning text-dark') ?>">
                                <?= strtoupper($latestProof['status']) ?>
                            </span>
                        </div>
                        <?php if (!empty($latestProof['reject_reason'])): ?>
                            <div class="mt-2 pt-2 border-top text-danger">
                                <strong>Alasan Ditolak:</strong> <?= esc($latestProof['reject_reason']) ?>
                            </div>
                        <?php endif; ?>
                    </div>

                    <?php if ($order['status'] === 'verifying_payment'): ?>
                        <div class="d-flex gap-2">
                            <form action="/admin/orders/<?= $order['id'] ?>/approve" method="POST" class="flex-fill">
                                <?= csrf_field() ?>
                                <button type="submit" class="btn btn-success w-100 py-2 fw-semibold" onclick="return confirm('Setujui bukti pembayaran pesanan ini?')">
                                    <i class="bi bi-check-circle me-1"></i> Setujui Pembayaran
                                </button>
                            </form>
                            <button type="button" class="btn btn-outline-danger flex-fill py-2 fw-semibold" data-bs-toggle="modal" data-bs-target="#modalRejectProof">
                                <i class="bi bi-x-circle me-1"></i> Tolak
                            </button>
                        </div>
                    <?php endif; ?>
                <?php endif; ?>
            </div>
        </div>

        <!-- 2. Pengiriman & Nomor Resi -->
        <div class="card border-0 shadow-sm rounded-3 mb-4">
            <div class="card-header bg-white py-3 border-bottom">
                <h6 class="mb-0 fw-bold"><i class="bi bi-truck me-2"></i>Ekspedisi & Resi Pengiriman</h6>
            </div>
            <div class="card-body p-4">
                <?php if ($shipment): ?>
                    <div class="bg-light rounded p-3">
                        <div class="small text-muted mb-1">Kurir Ekspedisi:</div>
                        <h6 class="fw-bold text-dark"><?= esc($shipment['courier']) ?></h6>
                        <div class="small text-muted mt-2 mb-1">Nomor Resi Paket:</div>
                        <div class="d-flex align-items-center gap-2">
                            <code class="fs-6 fw-bold"><?= esc($shipment['tracking_no']) ?></code>
                        </div>
                        <div class="small text-muted mt-2">Dikirim pada: <?= date('d M Y, H:i', strtotime($shipment['shipped_at'])) ?> WIB</div>
                    </div>
                <?php elseif ($order['status'] === 'processing'): ?>
                    <form action="/admin/orders/<?= $order['id'] ?>/ship" method="POST">
                        <?= csrf_field() ?>
                        <div class="mb-3">
                            <label class="form-label small fw-semibold">Pilih Ekspedisi <span class="text-danger">*</span></label>
                            <select name="courier" class="form-select" required>
                                <option value="J&T Express">J&T Express</option>
                                <option value="JNE">JNE</option>
                                <option value="SiCepat">SiCepat</option>
                                <option value="Pos Indonesia">Pos Indonesia</option>
                                <option value="Kurir Toko (Lokal Pontianak)">Kurir Toko (Lokal Pontianak)</option>
                            </select>
                        </div>
                        <div class="mb-3">
                            <label class="form-label small fw-semibold">Nomor Resi / Bukti Kirim <span class="text-danger">*</span></label>
                            <input type="text" name="tracking_no" class="form-control" placeholder="Contoh: JP1234567890" required>
                        </div>
                        <button type="submit" class="btn btn-primary w-100 py-2 fw-semibold">
                            <i class="bi bi-send me-1"></i> Simpan Resi & Set Dikirim
                        </button>
                    </form>
                <?php else: ?>
                    <div class="text-muted small text-center py-3">
                        Resi pengiriman dapat diinput setelah pembayaran diverifikasi (status: Diproses).
                    </div>
                <?php endif; ?>
            </div>
        </div>

        <!-- 3. Alamat Pengiriman Pelanggan -->
        <div class="card border-0 shadow-sm rounded-3">
            <div class="card-header bg-white py-3 border-bottom">
                <h6 class="mb-0 fw-bold"><i class="bi bi-geo-alt me-2"></i>Alamat Pengiriman</h6>
            </div>
            <div class="card-body p-4 small">
                <div class="fw-bold fs-6 text-dark"><?= esc($addressSnapshot['recipient_name'] ?? $order['customer_name']) ?></div>
                <div class="text-muted mb-2"><?= esc($addressSnapshot['recipient_phone'] ?? $order['customer_phone']) ?></div>
                <p class="mb-1 text-secondary"><?= esc($addressSnapshot['address_line'] ?? '-') ?></p>
                <div class="text-secondary"><?= esc($addressSnapshot['district'] ?? '') ?>, <?= esc($addressSnapshot['city'] ?? '') ?>, <?= esc($addressSnapshot['province'] ?? '') ?> <?= esc($addressSnapshot['postal_code'] ?? '') ?></div>
            </div>
        </div>
    </div>

    <!-- Kolom Kanan: Rincian Produk & Linimasa Log -->
    <div class="col-12 col-lg-7">
        <!-- Rincian Produk Pesanan -->
        <div class="card border-0 shadow-sm rounded-3 mb-4">
            <div class="card-header bg-white py-3 border-bottom">
                <h6 class="mb-0 fw-bold"><i class="bi bi-bag-check me-2"></i>Rincian Item Belanja</h6>
            </div>
            <div class="card-body p-0">
                <div class="table-responsive">
                    <table class="table align-middle mb-0">
                        <thead class="table-light small">
                            <tr>
                                <th class="ps-3">Item Hijab</th>
                                <th class="text-center">Harga Satuan</th>
                                <th class="text-center">Jumlah</th>
                                <th class="text-end pe-3">Subtotal</th>
                            </tr>
                        </thead>
                        <tbody>
                            <?php foreach ($items as $item): ?>
                                <tr>
                                    <td class="ps-3">
                                        <div class="fw-semibold text-dark"><?= esc($item['product_name']) ?></div>
                                        <small class="text-muted">Varian: <?= esc($item['variant_label']) ?></small>
                                    </td>
                                    <td class="text-center">Rp <?= number_format($item['unit_price'], 0, ',', '.') ?></td>
                                    <td class="text-center fw-bold"><?= $item['qty'] ?></td>
                                    <td class="text-end pe-3 fw-semibold">Rp <?= number_format($item['line_total'], 0, ',', '.') ?></td>
                                </tr>
                            <?php endforeach; ?>
                        </tbody>
                        <tfoot class="border-top">
                            <tr>
                                <td colspan="3" class="text-end text-muted ps-3">Subtotal Produk:</td>
                                <td class="text-end pe-3 fw-semibold">Rp <?= number_format($order['subtotal'], 0, ',', '.') ?></td>
                            </tr>
                            <tr>
                                <td colspan="3" class="text-end text-muted ps-3">Ongkos Kirim:</td>
                                <td class="text-end pe-3 fw-semibold">Rp <?= number_format($order['shipping_cost'], 0, ',', '.') ?></td>
                            </tr>
                            <tr class="table-light">
                                <td colspan="3" class="text-end fw-bold fs-6 ps-3">Total Pembayaran:</td>
                                <td class="text-end pe-3 fw-bold fs-6 text-danger">Rp <?= number_format($order['total'], 0, ',', '.') ?></td>
                            </tr>
                        </tfoot>
                    </table>
                </div>
            </div>
        </div>

        <!-- Linimasa Status Pesanan -->
        <div class="card border-0 shadow-sm rounded-3">
            <div class="card-header bg-white py-3 border-bottom">
                <h6 class="mb-0 fw-bold"><i class="bi bi-clock-history me-2"></i>Linimasa Status Transaksi</h6>
            </div>
            <div class="card-body p-4">
                <?php if (empty($logs)): ?>
                    <p class="text-muted small mb-0">Belum ada riwayat aktivitas.</p>
                <?php else: ?>
                    <ul class="list-unstyled mb-0 position-relative">
                        <?php foreach ($logs as $log): ?>
                            <li class="mb-3 d-flex gap-3">
                                <div class="text-primary pt-1"><i class="bi bi-circle-fill" style="font-size: 0.6rem;"></i></div>
                                <div>
                                    <div class="fw-semibold text-dark small">
                                        <?= strtoupper(str_replace('_', ' ', $log['to_status'])) ?>
                                        <?php if (!empty($log['actor_name'])): ?>
                                            <span class="text-muted fw-normal">(oleh <?= esc($log['actor_name']) ?>)</span>
                                        <?php endif; ?>
                                    </div>
                                    <?php if (!empty($log['note'])): ?>
                                        <div class="text-muted small"><?= esc($log['note']) ?></div>
                                    <?php endif; ?>
                                    <small class="text-secondary" style="font-size: 0.75rem;"><?= date('d M Y, H:i', strtotime($log['created_at'])) ?> WIB</small>
                                </div>
                            </li>
                        <?php endforeach; ?>
                    </ul>
                <?php endif; ?>
            </div>
        </div>
    </div>
</div>

<!-- Modal Zoom Bukti Pembayaran -->
<?php if (!empty($proofs)): ?>
<div class="modal fade" id="modalProofZoom" tabindex="-1">
    <div class="modal-dialog modal-dialog-centered modal-lg">
        <div class="modal-content">
            <div class="modal-header py-2">
                <h6 class="modal-title fw-bold">Bukti Transfer Pelanggan</h6>
                <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
            </div>
            <div class="modal-body p-1 text-center bg-dark">
                <img src="/<?= esc($proofs[0]['file_path']) ?>" class="img-fluid rounded" style="max-height: 80vh;">
            </div>
        </div>
    </div>
</div>
<?php endif; ?>

<!-- Modal Tolak Bukti Pembayaran -->
<div class="modal fade" id="modalRejectProof" tabindex="-1">
    <div class="modal-dialog">
        <div class="modal-content">
            <form action="/admin/orders/<?= $order['id'] ?>/reject" method="POST">
                <?= csrf_field() ?>
                <div class="modal-header">
                    <h6 class="modal-title fw-bold text-danger">Tolak Bukti Pembayaran</h6>
                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                </div>
                <div class="modal-body">
                    <p class="small text-muted">Jelaskan alasan penolakan agar pelanggan dapat memperbaikinya saat mengunggah ulang bukti pembayaran di aplikasi.</p>
                    <div class="mb-3">
                        <label class="form-label small fw-semibold">Alasan Penolakan <span class="text-danger">*</span></label>
                        <textarea name="reject_reason" class="form-control" rows="3" placeholder="Contoh: Nominal transfer kurang Rp 15.000 / Foto bukti buram tidak terbaca." required></textarea>
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-sm btn-secondary" data-bs-dismiss="modal">Batal</button>
                    <button type="submit" class="btn btn-sm btn-danger">Tolak Bukti Pembayaran</button>
                </div>
            </form>
        </div>
    </div>
</div>
<?= $this->endSection() ?>
