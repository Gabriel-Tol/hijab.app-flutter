<?php
    $uri = service('uri');
    $segment1 = $uri->getSegment(1) ?? '';
    $segment2 = $uri->getSegment(2) ?? '';
?>
<div class="sidebar">
    <div class="sidebar-brand">
        <i class="bi bi-gem"></i>
        <span>RnZ Store</span> Admin
    </div>
    <ul class="sidebar-menu">
        <li>
            <a href="/admin/dashboard" class="<?= $segment2 === 'dashboard' ? 'active' : '' ?>">
                <i class="bi bi-speedometer2"></i>
                <span>Dashboard</span>
            </a>
        </li>
        <li class="mt-3 mb-1 px-3 text-uppercase text-muted small fw-bold" style="font-size: 0.72rem; letter-spacing: 0.05rem;">
            Katalog & Inventori
        </li>
        <li>
            <a href="/admin/categories" class="<?= $segment2 === 'categories' ? 'active' : '' ?>">
                <i class="bi bi-tags"></i>
                <span>Kategori Produk</span>
            </a>
        </li>
        <li>
            <a href="/admin/products" class="<?= $segment2 === 'products' ? 'active' : '' ?>">
                <i class="bi bi-box-seam"></i>
                <span>Produk & Varian</span>
            </a>
        </li>
        <li>
            <a href="/admin/stock" class="<?= $segment2 === 'stock' ? 'active' : '' ?>">
                <i class="bi bi-arrow-left-right"></i>
                <span>Stok & Opname</span>
            </a>
        </li>
        <li class="mt-3 mb-1 px-3 text-uppercase text-muted small fw-bold" style="font-size: 0.72rem; letter-spacing: 0.05rem;">
            Transaksi
        </li>
        <li>
            <a href="/admin/orders" class="<?= $segment2 === 'orders' ? 'active' : '' ?> d-flex justify-content-between">
                <div>
                    <i class="bi bi-receipt"></i>
                    <span>Pesanan Masuk</span>
                </div>
            </a>
        </li>
        <li>
            <a href="/admin/reports" class="<?= $segment2 === 'reports' ? 'active' : '' ?>">
                <i class="bi bi-file-earmark-pdf"></i>
                <span>Laporan Penjualan</span>
            </a>
        </li>
        <li class="mt-3 mb-1 px-3 text-uppercase text-muted small fw-bold" style="font-size: 0.72rem; letter-spacing: 0.05rem;">
            Konfigurasi
        </li>
        <li>
            <a href="/admin/settings" class="<?= $segment2 === 'settings' ? 'active' : '' ?>">
                <i class="bi bi-gear"></i>
                <span>Pengaturan Toko</span>
            </a>
        </li>
    </ul>
</div>
