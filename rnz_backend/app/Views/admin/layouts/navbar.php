<div class="top-navbar d-flex justify-content-between align-items-center">
    <div class="d-flex align-items-center gap-3">
        <button class="btn btn-sm btn-light d-lg-none" onclick="toggleSidebar()">
            <i class="bi bi-list fs-5"></i>
        </button>
        <h5 class="mb-0 fw-semibold text-dark"><?= esc($title ?? 'Dashboard') ?></h5>
    </div>
    <div class="d-flex align-items-center gap-3">
        <div class="d-flex align-items-center gap-2">
            <div class="rounded-circle bg-secondary text-white d-flex align-items-center justify-content-center" style="width: 36px; height: 36px; font-weight: 600;">
                <?= strtoupper(substr(session()->get('admin_name') ?? 'A', 0, 1)) ?>
            </div>
            <div class="d-none d-sm-block text-start">
                <div class="fw-semibold text-dark small mb-0"><?= esc(session()->get('admin_name') ?? 'Admin') ?></div>
                <div class="text-muted" style="font-size: 0.75rem;">Pemilik Toko</div>
            </div>
        </div>
        <div class="vr mx-2"></div>
        <a href="/admin/logout" class="btn btn-sm btn-outline-danger" title="Keluar">
            <i class="bi bi-box-arrow-right me-1"></i> Keluar
        </a>
    </div>
</div>
