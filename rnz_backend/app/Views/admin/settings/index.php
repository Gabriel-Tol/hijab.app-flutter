<?= $this->extend('admin/layouts/main') ?>

<?= $this->section('content') ?>
<div class="mb-4">
    <h5 class="fw-bold font-serif mb-1">Pengaturan Toko</h5>
    <p class="text-muted small mb-0">Kelola nomor rekening pembayaran (Bank & E-Wallet) dan tarif flat ongkos kirim wilayah.</p>
</div>

<div class="row g-4">
    <!-- 1. Rekening Pembayaran -->
    <div class="col-12">
        <div class="card border-0 shadow-sm rounded-3">
            <div class="card-header bg-white py-3 d-flex justify-content-between align-items-center border-bottom">
                <h6 class="mb-0 fw-bold font-serif"><i class="bi bi-wallet2 me-2" style="color: var(--rnz-terracotta);"></i>Rekening Pembayaran & E-Wallet</h6>
                <button class="btn btn-sm btn-rnz" data-bs-toggle="modal" data-bs-target="#modalAddPayment">
                    <i class="bi bi-plus-lg me-1"></i> Tambah
                </button>
            </div>
            <div class="card-body p-0">
                <div class="table-responsive">
                    <table class="table table-hover align-middle mb-0">
                        <thead class="table-light small">
                            <tr>
                                <th class="ps-3">Provider</th>
                                <th>No. Rekening / HP</th>
                                <th>Atas Nama</th>
                                <th>Status</th>
                                <th class="text-end pe-3">Aksi</th>
                            </tr>
                        </thead>
                        <tbody>
                            <?php if (empty($paymentMethods)): ?>
                                <tr>
                                    <td colspan="5" class="text-center py-4 text-muted">Belum ada metode pembayaran.</td>
                                </tr>
                            <?php else: ?>
                                <?php foreach ($paymentMethods as $p): ?>
                                    <tr>
                                        <td class="ps-3">
                                            <div class="fw-bold text-dark"><?= esc($p['provider']) ?></div>
                                            <span class="badge bg-light text-muted border" style="font-size: 0.7rem;"><?= strtoupper($p['type']) ?></span>
                                        </td>
                                        <td><code><?= esc($p['account_no']) ?></code></td>
                                        <td class="small"><?= esc($p['account_name']) ?></td>
                                        <td>
                                            <?php if ($p['is_active']): ?>
                                                <span class="badge badge-completed small rounded-pill px-2">Aktif</span>
                                            <?php else: ?>
                                                <span class="badge badge-waiting small rounded-pill px-2">Nonaktif</span>
                                            <?php endif; ?>
                                        </td>
                                        <td class="text-end pe-3">
                                            <div class="d-flex justify-content-end align-items-center flex-nowrap gap-1">
                                                <button class="btn btn-sm btn-outline-rnz py-1 px-2" data-bs-toggle="modal" data-bs-target="#modalEditPay<?= $p['id'] ?>">
                                                    <i class="bi bi-pencil"></i>
                                                </button>
                                                <form action="/admin/settings/payment-method/delete/<?= $p['id'] ?>" method="POST" class="d-inline m-0" onsubmit="return rnzConfirm('Hapus metode pembayaran ini?')">
                                                    <?= csrf_field() ?>
                                                    <button type="submit" class="btn btn-sm btn-outline-terracotta py-1 px-2" title="Hapus">
                                                        <i class="bi bi-trash"></i>
                                                    </button>
                                                </form>
                                            </div>
                                        </td>
                                    </tr>

                                    <!-- Modal Edit Payment -->
                                    <div class="modal fade" id="modalEditPay<?= $p['id'] ?>" tabindex="-1">
                                        <div class="modal-dialog">
                                            <div class="modal-content">
                                                <form action="/admin/settings/payment-method/update/<?= $p['id'] ?>" method="POST">
                                                    <?= csrf_field() ?>
                                                    <div class="modal-header">
                                                        <h6 class="modal-title fw-bold">Ubah Rekening Pembayaran</h6>
                                                        <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                                                    </div>
                                                    <div class="modal-body">
                                                        <div class="mb-3">
                                                            <label class="form-label small fw-semibold">Tipe Pembayaran</label>
                                                            <select name="type" class="form-select">
                                                                <option value="bank" <?= $p['type'] === 'bank' ? 'selected' : '' ?>>Transfer Bank</option>
                                                                <option value="ewallet" <?= $p['type'] === 'ewallet' ? 'selected' : '' ?>>E-Wallet</option>
                                                            </select>
                                                        </div>
                                                        <div class="mb-3">
                                                            <label class="form-label small fw-semibold">Nama Provider / Bank</label>
                                                            <input type="text" name="provider" class="form-control" value="<?= esc($p['provider']) ?>" required>
                                                        </div>
                                                        <div class="mb-3">
                                                            <label class="form-label small fw-semibold">Nomor Rekening / HP</label>
                                                            <input type="text" name="account_no" class="form-control" value="<?= esc($p['account_no']) ?>" required>
                                                        </div>
                                                        <div class="mb-3">
                                                            <label class="form-label small fw-semibold">Atas Nama Penerima</label>
                                                            <input type="text" name="account_name" class="form-control" value="<?= esc($p['account_name']) ?>" required>
                                                        </div>
                                                        <div class="form-check form-switch">
                                                            <input class="form-check-input" type="checkbox" name="is_active" value="1" id="swPay<?= $p['id'] ?>" <?= $p['is_active'] ? 'checked' : '' ?>>
                                                            <label class="form-check-label small" for="swPay<?= $p['id'] ?>">Aktifkan opsi ini di aplikasi</label>
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
    </div>

    <!-- 2. Tarif Ongkos Kirim -->
    <div class="col-12">
        <div class="card border-0 shadow-sm rounded-3">
            <div class="card-header bg-white py-3 d-flex justify-content-between align-items-center border-bottom">
                <h6 class="mb-0 fw-bold font-serif"><i class="bi bi-truck me-2" style="color: var(--rnz-terracotta);"></i>Tarif Ongkir Wilayah</h6>
                <button class="btn btn-sm btn-rnz" data-bs-toggle="modal" data-bs-target="#modalAddShipping">
                    <i class="bi bi-plus-lg me-1"></i> Tambah
                </button>
            </div>
            <div class="card-body p-0">
                <div class="table-responsive">
                    <table class="table table-hover align-middle mb-0">
                        <thead class="table-light small">
                            <tr>
                                <th class="ps-3">Wilayah Pengiriman</th>
                                <th>Tarif Flat</th>
                                <th>Status</th>
                                <th class="text-end pe-3">Aksi</th>
                            </tr>
                        </thead>
                        <tbody>
                            <?php if (empty($shippingRates)): ?>
                                <tr>
                                    <td colspan="4" class="text-center py-4 text-muted">Belum ada tarif pengiriman.</td>
                                </tr>
                            <?php else: ?>
                                <?php foreach ($shippingRates as $s): ?>
                                    <tr>
                                        <td class="ps-3 fw-semibold text-dark"><?= esc($s['region_name']) ?></td>
                                        <td class="fw-bold" style="color: var(--rnz-forest);">Rp <?= number_format($s['cost'], 0, ',', '.') ?></td>
                                        <td>
                                            <?php if ($s['is_active']): ?>
                                                <span class="badge badge-completed small rounded-pill px-2">Aktif</span>
                                            <?php else: ?>
                                                <span class="badge badge-waiting small rounded-pill px-2">Nonaktif</span>
                                            <?php endif; ?>
                                        </td>
                                        <td class="text-end pe-3">
                                            <div class="d-flex justify-content-end align-items-center flex-nowrap gap-1">
                                                <button class="btn btn-sm btn-outline-rnz py-1 px-2" data-bs-toggle="modal" data-bs-target="#modalEditShip<?= $s['id'] ?>">
                                                    <i class="bi bi-pencil"></i>
                                                </button>
                                                <form action="/admin/settings/shipping-rate/delete/<?= $s['id'] ?>" method="POST" class="d-inline m-0" onsubmit="return rnzConfirm('Hapus tarif ongkir ini?')">
                                                    <?= csrf_field() ?>
                                                    <button type="submit" class="btn btn-sm btn-outline-terracotta py-1 px-2" title="Hapus">
                                                        <i class="bi bi-trash"></i>
                                                    </button>
                                                </form>
                                            </div>
                                        </td>
                                    </tr>

                                    <!-- Modal Edit Shipping -->
                                    <div class="modal fade" id="modalEditShip<?= $s['id'] ?>" tabindex="-1">
                                        <div class="modal-dialog">
                                            <div class="modal-content">
                                                <form action="/admin/settings/shipping-rate/update/<?= $s['id'] ?>" method="POST">
                                                    <?= csrf_field() ?>
                                                    <div class="modal-header">
                                                        <h6 class="modal-title fw-bold">Ubah Tarif Wilayah</h6>
                                                        <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                                                    </div>
                                                    <div class="modal-body">
                                                        <div class="mb-3">
                                                            <label class="form-label small fw-semibold">Nama Wilayah</label>
                                                            <input type="text" name="region_name" class="form-control" value="<?= esc($s['region_name']) ?>" required>
                                                        </div>
                                                        <div class="mb-3">
                                                            <label class="form-label small fw-semibold">Tarif Flat (Rp)</label>
                                                            <div class="input-group">
                                                                <span class="input-group-text bg-light">Rp</span>
                                                                <input type="number" name="cost" class="form-control" value="<?= $s['cost'] ?>" min="0" required>
                                                            </div>
                                                        </div>
                                                        <div class="form-check form-switch">
                                                            <input class="form-check-input" type="checkbox" name="is_active" value="1" id="swShip<?= $s['id'] ?>" <?= $s['is_active'] ? 'checked' : '' ?>>
                                                            <label class="form-check-label small" for="swShip<?= $s['id'] ?>">Aktifkan tarif wilayah ini</label>
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
    </div>
</div>

<!-- Modal Tambah Pembayaran -->
<div class="modal fade" id="modalAddPayment" tabindex="-1">
    <div class="modal-dialog">
        <div class="modal-content">
            <form action="/admin/settings/payment-method" method="POST">
                <?= csrf_field() ?>
                <div class="modal-header">
                    <h6 class="modal-title fw-bold">Tambah Metode Pembayaran</h6>
                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                </div>
                <div class="modal-body">
                    <div class="mb-3">
                        <label class="form-label small fw-semibold">Tipe Pembayaran</label>
                        <select name="type" class="form-select">
                            <option value="bank">Transfer Bank</option>
                            <option value="ewallet">E-Wallet (GoPay / Dana / OVO / ShopeePay)</option>
                        </select>
                    </div>
                    <div class="mb-3">
                        <label class="form-label small fw-semibold">Nama Provider / Bank</label>
                        <input type="text" name="provider" class="form-control" placeholder="Contoh: Bank BNI" required>
                    </div>
                    <div class="mb-3">
                        <label class="form-label small fw-semibold">Nomor Rekening / No. HP</label>
                        <input type="text" name="account_no" class="form-control" placeholder="Contoh: 0123456789" required>
                    </div>
                    <div class="mb-3">
                        <label class="form-label small fw-semibold">Atas Nama Penerima</label>
                        <input type="text" name="account_name" class="form-control" placeholder="Contoh: RnZ Store - Rafly" required>
                    </div>
                    <div class="form-check form-switch">
                        <input class="form-check-input" type="checkbox" name="is_active" value="1" id="swPayNew" checked>
                        <label class="form-check-label small" for="swPayNew">Aktifkan opsi ini di aplikasi</label>
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-sm btn-secondary" data-bs-dismiss="modal">Batal</button>
                    <button type="submit" class="btn btn-sm btn-rnz">Tambah Rekening</button>
                </div>
            </form>
        </div>
    </div>
</div>

<!-- Modal Tambah Shipping -->
<div class="modal fade" id="modalAddShipping" tabindex="-1">
    <div class="modal-dialog">
        <div class="modal-content">
            <form action="/admin/settings/shipping-rate" method="POST">
                <?= csrf_field() ?>
                <div class="modal-header">
                    <h6 class="modal-title fw-bold">Tambah Tarif Wilayah</h6>
                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                </div>
                <div class="modal-body">
                    <div class="mb-3">
                        <label class="form-label small fw-semibold">Nama Wilayah</label>
                        <input type="text" name="region_name" class="form-control" placeholder="Contoh: Singkawang / Sambas" required>
                    </div>
                    <div class="mb-3">
                        <label class="form-label small fw-semibold">Tarif Flat (Rp)</label>
                        <div class="input-group">
                            <span class="input-group-text bg-light">Rp</span>
                            <input type="number" name="cost" class="form-control" placeholder="20000" min="0" required>
                        </div>
                    </div>
                    <div class="form-check form-switch">
                        <input class="form-check-input" type="checkbox" name="is_active" value="1" id="swShipNew" checked>
                        <label class="form-check-label small" for="swShipNew">Aktifkan tarif wilayah ini</label>
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-sm btn-secondary" data-bs-dismiss="modal">Batal</button>
                    <button type="submit" class="btn btn-sm btn-rnz">Tambah Tarif</button>
                </div>
            </form>
        </div>
    </div>
</div>
<?= $this->endSection() ?>
