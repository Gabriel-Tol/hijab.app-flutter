<div class="top-navbar d-flex justify-content-between align-items-center">
    <div class="d-flex align-items-center gap-3">
        <button class="btn btn-sm btn-light border d-lg-none" onclick="toggleSidebar()">
            <i class="bi bi-list fs-5"></i>
        </button>
        <h5 class="mb-0 fw-bold font-serif" style="color: var(--rnz-ink);"><?= esc($title ?? 'Dashboard') ?></h5>
    </div>
    <div class="d-flex align-items-center gap-3">
        <div class="d-flex align-items-center gap-2">
            <div class="rounded-circle d-flex align-items-center justify-content-center shadow-sm" style="width: 38px; height: 38px; font-weight: 700; background-color: var(--rnz-forest); color: #FFFFFF; font-size: 0.95rem;">
                <?= strtoupper(substr(session()->get('admin_name') ?? 'A', 0, 1)) ?>
            </div>
            <div class="d-none d-sm-block text-start">
                <div class="fw-semibold small mb-0" style="color: var(--rnz-ink);"><?= esc(session()->get('admin_name') ?? 'Admin') ?></div>
                <div style="font-size: 0.75rem; color: var(--rnz-muted);">Pemilik Toko</div>
            </div>
        </div>
        <div class="vr mx-1" style="color: var(--rnz-line);"></div>
        <a href="/admin/logout" class="btn btn-sm btn-outline-terracotta" title="Keluar">
            <i class="bi bi-box-arrow-right me-1"></i> Keluar
        </a>
    </div>
</div>
