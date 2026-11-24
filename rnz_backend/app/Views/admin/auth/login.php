<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Login Admin — RnZ Store</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css">
    <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700&display=swap" rel="stylesheet">
    <style>
        body {
            font-family: 'Plus Jakarta Sans', sans-serif;
            background-color: #F8F9FA;
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
        }
        .login-card {
            max-width: 420px;
            width: 100%;
            background: #FFFFFF;
            border-radius: 16px;
            box-shadow: 0 10px 30px rgba(0, 0, 0, 0.05);
            border: 1px solid #E2E8F0;
            overflow: hidden;
        }
        .login-header {
            background-color: #800020; /* Burgundy */
            color: #FFFFFF;
            padding: 32px 24px;
            text-align: center;
        }
        .btn-rnz {
            background-color: #800020;
            color: #FFFFFF;
            border: none;
            padding: 12px;
            font-weight: 600;
            border-radius: 8px;
        }
        .btn-rnz:hover {
            background-color: #630018;
            color: #FFFFFF;
        }
    </style>
</head>
<body>
    <div class="login-card">
        <div class="login-header">
            <h4 class="fw-bold mb-1"><i class="bi bi-gem me-2"></i>RnZ Store</h4>
            <p class="text-white-50 small mb-0">Panel Pengelola Toko Hijab</p>
        </div>
        <div class="p-4">
            <?php if (session()->getFlashdata('error')): ?>
                <div class="alert alert-danger small py-2 mb-3">
                    <i class="bi bi-exclamation-circle-fill me-1"></i><?= session()->getFlashdata('error') ?>
                </div>
            <?php endif; ?>

            <?php if (session()->getFlashdata('success')): ?>
                <div class="alert alert-success small py-2 mb-3">
                    <i class="bi bi-check-circle-fill me-1"></i><?= session()->getFlashdata('success') ?>
                </div>
            <?php endif; ?>

            <form action="/admin/login" method="POST">
                <?= csrf_field() ?>
                <div class="mb-3">
                    <label class="form-label small fw-semibold text-secondary">Alamat Email</label>
                    <div class="input-group">
                        <span class="input-group-text bg-light text-muted"><i class="bi bi-envelope"></i></span>
                        <input type="email" name="email" class="form-control" placeholder="admin@rnzstore.com" value="<?= old('email') ?>" required autofocus>
                    </div>
                </div>

                <div class="mb-4">
                    <label class="form-label small fw-semibold text-secondary">Kata Sandi</label>
                    <div class="input-group">
                        <span class="input-group-text bg-light text-muted"><i class="bi bi-lock"></i></span>
                        <input type="password" name="password" class="form-control" placeholder="••••••••" required>
                    </div>
                </div>

                <button type="submit" class="btn btn-rnz w-100 mb-2">
                    Masuk ke Dashboard
                </button>
            </form>
            <div class="text-center mt-3">
                <small class="text-muted">Aplikasi Mobile E-Commerce RnZ Store</small>
            </div>
        </div>
    </div>
</body>
</html>
