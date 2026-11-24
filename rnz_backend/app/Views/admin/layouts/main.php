<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><?= esc($title ?? 'Admin Dashboard') ?> — RnZ Store</title>
    <!-- Bootstrap 5 CSS -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <!-- Bootstrap Icons -->
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css">
    <!-- Google Fonts -->
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700&display=swap" rel="stylesheet">
    
    <style>
        :root {
            --rnz-primary: #800020; /* Burgundy */
            --rnz-primary-hover: #630018;
            --rnz-gold: #C5A059;
            --rnz-bg: #F8F9FA;
            --rnz-sidebar-bg: #1F2421;
        }
        body {
            font-family: 'Plus Jakarta Sans', sans-serif;
            background-color: var(--rnz-bg);
            color: #2D3748;
        }
        .sidebar {
            width: 260px;
            background-color: var(--rnz-sidebar-bg);
            min-height: 100vh;
            color: #E2E8F0;
            position: fixed;
            top: 0;
            left: 0;
            z-index: 1000;
            transition: all 0.3s;
        }
        .sidebar-brand {
            padding: 24px 20px;
            font-weight: 700;
            font-size: 1.25rem;
            color: #FFFFFF;
            border-bottom: 1px solid rgba(255, 255, 255, 0.08);
            display: flex;
            align-items: center;
            gap: 10px;
        }
        .sidebar-brand span {
            color: var(--rnz-gold);
        }
        .sidebar-menu {
            padding: 16px 12px;
            list-style: none;
            margin: 0;
        }
        .sidebar-menu li {
            margin-bottom: 4px;
        }
        .sidebar-menu a {
            display: flex;
            align-items: center;
            gap: 12px;
            padding: 10px 16px;
            color: #A0AEC0;
            text-decoration: none;
            border-radius: 8px;
            font-size: 0.92rem;
            font-weight: 500;
            transition: all 0.2s;
        }
        .sidebar-menu a:hover, .sidebar-menu a.active {
            background-color: rgba(255, 255, 255, 0.08);
            color: #FFFFFF;
        }
        .sidebar-menu a.active {
            background-color: var(--rnz-primary);
            color: #FFFFFF;
        }
        .main-wrapper {
            margin-left: 260px;
            min-height: 100vh;
            display: flex;
            flex-direction: column;
        }
        .top-navbar {
            background-color: #FFFFFF;
            border-bottom: 1px solid #E2E8F0;
            padding: 14px 28px;
            position: sticky;
            top: 0;
            z-index: 999;
        }
        .content-area {
            padding: 28px;
            flex: 1;
        }
        .card-stat {
            border: none;
            border-radius: 12px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.03);
            transition: transform 0.2s;
        }
        .card-stat:hover {
            transform: translateY(-2px);
        }
        .stat-icon {
            width: 48px;
            height: 48px;
            border-radius: 10px;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 1.4rem;
        }
        .btn-rnz {
            background-color: var(--rnz-primary);
            color: #FFFFFF;
            border: none;
        }
        .btn-rnz:hover {
            background-color: var(--rnz-primary-hover);
            color: #FFFFFF;
        }
        .badge-verifying {
            background-color: #FEF3C7;
            color: #92400E;
        }
        .badge-processing {
            background-color: #DBEAFE;
            color: #1E40AF;
        }
        .badge-shipped {
            background-color: #E0E7FF;
            color: #3730A3;
        }
        .badge-completed {
            background-color: #D1FAE5;
            color: #065F46;
        }
        .badge-cancelled {
            background-color: #FEE2E2;
            color: #991B1B;
        }
        @media (max-width: 991px) {
            .sidebar {
                margin-left: -260px;
            }
            .sidebar.show {
                margin-left: 0;
            }
            .main-wrapper {
                margin-left: 0;
            }
        }
    </style>
</head>
<body>
    <!-- Sidebar -->
    <?= $this->include('admin/layouts/sidebar') ?>

    <!-- Main Content Wrapper -->
    <div class="main-wrapper">
        <!-- Top Navbar -->
        <?= $this->include('admin/layouts/navbar') ?>

        <!-- Content Area -->
        <div class="content-area">
            <!-- Flash Messages -->
            <?php if (session()->getFlashdata('success')): ?>
                <div class="alert alert-success alert-dismissible fade show" role="alert">
                    <i class="bi bi-check-circle-fill me-2"></i><?= session()->getFlashdata('success') ?>
                    <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
                </div>
            <?php endif; ?>

            <?php if (session()->getFlashdata('error')): ?>
                <div class="alert alert-danger alert-dismissible fade show" role="alert">
                    <i class="bi bi-exclamation-triangle-fill me-2"></i><?= session()->getFlashdata('error') ?>
                    <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
                </div>
            <?php endif; ?>

            <?php if (session()->getFlashdata('errors')): ?>
                <div class="alert alert-danger alert-dismissible fade show" role="alert">
                    <i class="bi bi-exclamation-triangle-fill me-2"></i>Terdapat kesalahan pada input Anda:
                    <ul class="mb-0 mt-2">
                        <?php foreach (session()->getFlashdata('errors') as $err): ?>
                            <li><?= esc($err) ?></li>
                        <?php endforeach; ?>
                    </ul>
                    <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
                </div>
            <?php endif; ?>

            <!-- Page Content -->
            <?= $this->renderSection('content') ?>
        </div>
    </div>

    <!-- Bootstrap 5 JS Bundle -->
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
    <script>
        function toggleSidebar() {
            document.querySelector('.sidebar').classList.toggle('show');
        }
    </script>
</body>
</html>
