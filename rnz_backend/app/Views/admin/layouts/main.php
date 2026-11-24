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
    <!-- Google Fonts: Manrope (Body/UI) & Fraunces (Headings/Brand) -->
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Fraunces:opsz,wght@9..144,500;600;700&family=Manrope:wght@400;500;600;700&display=swap" rel="stylesheet">
    
    <style>
        :root {
            /* RnZ Store Official Brand Palette (Matching Flutter constants.dart) */
            --rnz-forest: #223A2D;
            --rnz-forest-hover: #192D23;
            --rnz-forest-light: #EAF0EC;
            --rnz-terracotta: #C06B4E;
            --rnz-terracotta-hover: #A85A3F;
            --rnz-terracotta-light: #FBF0EB;
            --rnz-ivory: #F7F2E9;
            --rnz-surface: #FCFAF6;
            --rnz-ink: #1B1A17;
            --rnz-muted: #5A564E;
            --rnz-line: #E3DACB;

            /* Functional Token Mappings */
            --rnz-primary: var(--rnz-forest);
            --rnz-primary-hover: var(--rnz-forest-hover);
            --rnz-accent: var(--rnz-terracotta);
            --rnz-accent-hover: var(--rnz-terracotta-hover);
            --rnz-bg: var(--rnz-ivory);
            --rnz-card-bg: #FFFFFF;
            --rnz-sidebar-bg: #1A2D23;
            --rnz-sidebar-muted: #8E9F94;

            /* Semantic Status Tokens (Flutter AppColors) */
            --rnz-success: #3D6B4F;
            --rnz-success-bg: #EAF3EC;
            --rnz-success-border: #C4E1CC;
            --rnz-danger: #A84532;
            --rnz-danger-bg: #FDF0ED;
            --rnz-danger-border: #F5CBC3;
            --rnz-warning: #B07A2A;
            --rnz-warning-bg: #FEF8EC;
            --rnz-warning-border: #F7E4B8;
            --rnz-info: #2D5F7C;
            --rnz-info-bg: #EEF6FA;
            --rnz-info-border: #CFE4F0;
        }

        body {
            font-family: 'Manrope', -apple-system, BlinkMacSystemFont, sans-serif;
            background-color: var(--rnz-bg);
            color: var(--rnz-ink);
            line-height: 1.5;
            -webkit-font-smoothing: antialiased;
        }

        h1, h2, h3, h4, h5, h6, .font-serif {
            font-family: 'Fraunces', Georgia, serif;
            color: var(--rnz-ink);
            font-weight: 600;
            letter-spacing: -0.015em;
        }

        .sidebar {
            width: 260px;
            background-color: var(--rnz-sidebar-bg);
            min-height: 100vh;
            color: #E2EBE5;
            position: fixed;
            top: 0;
            left: 0;
            z-index: 1000;
            transition: all 0.3s ease;
            border-right: 1px solid rgba(227, 218, 203, 0.12);
        }

        .sidebar-brand {
            padding: 24px 20px;
            font-family: 'Fraunces', serif;
            font-weight: 700;
            font-size: 1.3rem;
            color: #FFFFFF;
            border-bottom: 1px solid rgba(255, 255, 255, 0.08);
            display: flex;
            align-items: center;
            gap: 10px;
            letter-spacing: -0.02em;
        }

        .sidebar-brand i {
            color: var(--rnz-terracotta);
            font-size: 1.25rem;
        }

        .sidebar-brand span {
            color: #FFFFFF;
        }

        .sidebar-brand .brand-badge {
            font-family: 'Manrope', sans-serif;
            font-size: 0.68rem;
            font-weight: 700;
            background-color: rgba(192, 107, 78, 0.2);
            color: #E8A893;
            border: 1px solid rgba(192, 107, 78, 0.4);
            padding: 2px 7px;
            border-radius: 999px;
            text-transform: uppercase;
            letter-spacing: 0.04em;
        }

        .sidebar-menu {
            padding: 16px 12px;
            list-style: none;
            margin: 0;
        }

        .sidebar-menu li {
            margin-bottom: 4px;
        }

        .sidebar-section-title {
            font-family: 'Manrope', sans-serif;
            font-size: 0.7rem;
            font-weight: 700;
            text-transform: uppercase;
            letter-spacing: 0.06em;
            color: var(--rnz-sidebar-muted);
            padding: 12px 14px 4px 14px;
        }

        .sidebar-menu a {
            display: flex;
            align-items: center;
            gap: 12px;
            padding: 10px 14px;
            color: #B5C4BC;
            text-decoration: none;
            border-radius: 10px;
            font-size: 0.9rem;
            font-weight: 500;
            transition: all 0.2s ease;
            border-left: 3px solid transparent;
        }

        .sidebar-menu a:hover {
            background-color: rgba(255, 255, 255, 0.06);
            color: #FFFFFF;
        }

        .sidebar-menu a.active {
            background-color: rgba(255, 255, 255, 0.12);
            color: #FFFFFF;
            font-weight: 600;
            border-left: 3px solid var(--rnz-terracotta);
            box-shadow: 0 2px 8px rgba(0, 0, 0, 0.15);
        }

        .sidebar-menu a.active i {
            color: var(--rnz-terracotta);
        }

        .main-wrapper {
            margin-left: 260px;
            min-height: 100vh;
            display: flex;
            flex-direction: column;
        }

        .top-navbar {
            background-color: #FFFFFF;
            border-bottom: 1px solid var(--rnz-line);
            padding: 14px 28px;
            position: sticky;
            top: 0;
            z-index: 999;
        }

        .content-area {
            padding: 28px;
            flex: 1;
        }

        /* Card & Surface Styling */
        .card {
            background-color: #FFFFFF;
            border: 1px solid var(--rnz-line);
            border-radius: 12px;
            box-shadow: 0 2px 8px rgba(34, 58, 45, 0.03);
        }

        .card-header {
            background-color: #FFFFFF;
            border-bottom: 1px solid var(--rnz-line);
            padding: 16px 20px;
        }

        .card-stat {
            border: 1px solid var(--rnz-line);
            border-radius: 12px;
            box-shadow: 0 2px 8px rgba(34, 58, 45, 0.03);
            transition: transform 0.2s, box-shadow 0.2s;
        }

        .card-stat:hover {
            transform: translateY(-2px);
            box-shadow: 0 6px 16px rgba(34, 58, 45, 0.06);
        }

        .stat-icon {
            width: 48px;
            height: 48px;
            border-radius: 12px;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 1.35rem;
        }

        /* Buttons matching Flutter tokens */
        .btn-rnz {
            background-color: var(--rnz-forest);
            color: #FFFFFF;
            border: 1px solid var(--rnz-forest);
            padding: 8px 18px;
            font-weight: 600;
            border-radius: 8px;
            transition: all 0.2s ease;
        }

        .btn-rnz:hover, .btn-rnz:focus {
            background-color: var(--rnz-forest-hover);
            border-color: var(--rnz-forest-hover);
            color: #FFFFFF;
            box-shadow: 0 2px 6px rgba(34, 58, 45, 0.2);
        }

        .btn-rnz-accent {
            background-color: var(--rnz-terracotta);
            color: #FFFFFF;
            border: 1px solid var(--rnz-terracotta);
            padding: 8px 18px;
            font-weight: 600;
            border-radius: 8px;
            transition: all 0.2s ease;
        }

        .btn-rnz-accent:hover, .btn-rnz-accent:focus {
            background-color: var(--rnz-terracotta-hover);
            border-color: var(--rnz-terracotta-hover);
            color: #FFFFFF;
            box-shadow: 0 2px 6px rgba(192, 107, 78, 0.25);
        }

        .btn-outline-rnz {
            background-color: transparent;
            color: var(--rnz-forest);
            border: 1.5px solid var(--rnz-forest);
            padding: 7px 16px;
            font-weight: 600;
            border-radius: 8px;
            transition: all 0.2s ease;
        }

        .btn-outline-rnz:hover {
            background-color: var(--rnz-forest);
            color: #FFFFFF;
        }

        .btn-outline-terracotta {
            background-color: transparent;
            color: var(--rnz-terracotta);
            border: 1.5px solid var(--rnz-terracotta);
            padding: 7px 16px;
            font-weight: 600;
            border-radius: 8px;
            transition: all 0.2s ease;
        }

        .btn-outline-terracotta:hover {
            background-color: var(--rnz-terracotta);
            color: #FFFFFF;
        }

        /* Form Controls */
        .form-control, .form-select {
            border: 1px solid var(--rnz-line);
            border-radius: 8px;
            color: var(--rnz-ink);
            padding: 8px 12px;
            font-size: 0.92rem;
        }

        .form-control:focus, .form-select:focus {
            border-color: var(--rnz-forest);
            box-shadow: 0 0 0 3px rgba(34, 58, 45, 0.12);
            outline: none;
        }

        .input-group-text {
            border: 1px solid var(--rnz-line);
            background-color: var(--rnz-surface);
            color: var(--rnz-muted);
        }

        /* Tables */
        .table {
            color: var(--rnz-ink);
            border-color: var(--rnz-line);
        }

        .table thead th {
            background-color: #F3ECE1;
            color: var(--rnz-ink);
            font-weight: 600;
            font-size: 0.85rem;
            text-transform: uppercase;
            letter-spacing: 0.03em;
            border-bottom: 1.5px solid var(--rnz-line);
            padding: 12px 14px;
        }

        .table tbody td {
            border-bottom: 1px solid var(--rnz-line);
            padding: 12px 14px;
            font-size: 0.9rem;
        }

        .table-hover tbody tr:hover {
            background-color: rgba(34, 58, 45, 0.02);
        }

        /* Order Status Badges matching Flutter semantics */
        .badge-verifying {
            background-color: var(--rnz-warning-bg);
            color: var(--rnz-warning);
            border: 1px solid var(--rnz-warning-border);
            font-weight: 600;
        }

        .badge-processing {
            background-color: var(--rnz-info-bg);
            color: var(--rnz-info);
            border: 1px solid var(--rnz-info-border);
            font-weight: 600;
        }

        .badge-shipped {
            background-color: #F3F0F9;
            color: #553C7B;
            border: 1px solid #E0D8EE;
            font-weight: 600;
        }

        .badge-completed {
            background-color: var(--rnz-success-bg);
            color: var(--rnz-success);
            border: 1px solid var(--rnz-success-border);
            font-weight: 600;
        }

        .badge-cancelled {
            background-color: var(--rnz-danger-bg);
            color: var(--rnz-danger);
            border: 1px solid var(--rnz-danger-border);
            font-weight: 600;
        }

        .badge-waiting {
            background-color: #F4EFE6;
            color: var(--rnz-muted);
            border: 1px solid var(--rnz-line);
            font-weight: 600;
        }

        /* Alerts */
        .alert-success {
            background-color: var(--rnz-success-bg);
            border-color: var(--rnz-success-border);
            color: var(--rnz-success);
            border-radius: 10px;
        }

        .alert-danger {
            background-color: var(--rnz-danger-bg);
            border-color: var(--rnz-danger-border);
            color: var(--rnz-danger);
            border-radius: 10px;
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
    <!-- SweetAlert2 for interactive alerts -->
    <script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>
    <script>
        function toggleSidebar() {
            document.querySelector('.sidebar').classList.toggle('show');
        }

        // RNZ Store SweetAlert confirmation - replaces window.confirm()
        // Usage:
        // - On form onsubmit: onsubmit="return rnzConfirm('Pesan', this)"
        // - On button with form attribute: onclick="return rnzConfirm('Pesan', this)"
        async function rnzConfirm(message, element) {
            const result = await Swal.fire({
                title: 'Konfirmasi?',
                text: message,
                icon: 'warning',
                showCancelButton: true,
                confirmButtonColor: 'var(--rnz-terracotta)',
                cancelButtonColor: 'var(--rnz-muted)',
                confirmButtonText: 'Ya, lanjutkan',
                cancelButtonText: 'Batal',
                customClass: {
                    popup: 'swal-rnz',
                    title: 'font-serif',
                    confirmButton: 'swal-confirm',
                    cancelButton: 'swal-cancel'
                }
            });
            if (!result.isConfirmed) {
                return false;
            }
            
            // Handle button with form attribute
            if (element && element.form && typeof element.form.submit === 'function') {
                element.form.submit();
                return false;
            }
            
            // For direct form submission (onsubmit)
            if (element && typeof element.submit === 'function') {
                element.submit();
            }
            
            return false;
        }

        // RNZ Store success toast - shows a brief success notification
        // Usage: rnzToast('Pesan berhasil!'); or rnzToast('Pesan berhasil!', 'success');
        function rnzToast(message, type = 'success') {
            Swal.fire({
                toast: true,
                position: 'top-end',
                showConfirmButton: false,
                timer: 3000,
                timerProgressBar: true,
                icon: type,
                title: message,
                customClass: {
                    popup: 'swal-rnz-toast',
                    title: 'font-serif'
                }
            });
        }

        // Custom CSS for SweetAlert2 (matches RnZ brand)
        const rnzSweetAlertStyle = document.createElement('style');
        rnzSweetAlertStyle.textContent = \`
            .swal-rnz {
                border-radius: 12px !important;
                background: var(--rnz-surface) !important;
            }
            .swal-rnz .swal-icon {
                color: var(--rnz-warning) !important;
            }
            .swal-rnz .swal-icon.swal-icon-warning::before {
                color: var(--rnz-warning) !important;
            }
            .swal-rnz .swal-title {
                color: var(--rnz-ink) !important;
                font-family: 'Fraunces', serif !important;
                font-weight: 600 !important;
                margin-bottom: 12px !important;
            }
            .swal-rnz .swal-text {
                color: var(--rnz-ink) !important;
                font-family: 'Manrope', sans-serif !important;
                font-size: 14px !important;
            }
            .swal-rnz .swal-confirm-btn {
                font-family: 'Manrope', sans-serif !important;
                font-weight: 600 !important;
            }
            .swal-rnz .swal-cancel-btn {
                font-family: 'Manrope', sans-serif !important;
            }
        \`;
        document.head.appendChild(rnzSweetAlertStyle);

        // Check for flash messages and display them
        (function() {
            <?php if (session()->has('success')): ?>
                rnzToast('<?= esc(session()->get('success')) ?>', 'success');
            <?php endif; ?>
            <?php if (session()->has('error')): ?>
                rnzToast('<?= esc(session()->get('error')) ?>', 'error');
            <?php endif; ?>
        })();
    </script>
</body>
</html>
