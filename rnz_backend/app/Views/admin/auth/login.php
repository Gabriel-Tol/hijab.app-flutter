<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Login Admin — RnZ Store</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css">
    <link href="https://fonts.googleapis.com/css2?family=Fraunces:opsz,wght@9..144,500;600;700&family=Manrope:wght@400;500;600;700&display=swap" rel="stylesheet">
    <style>
        :root {
            --rnz-forest: #223A2D;
            --rnz-forest-hover: #192D23;
            --rnz-terracotta: #C06B4E;
            --rnz-terracotta-hover: #A85A3F;
            --rnz-ivory: #F7F2E9;
            --rnz-surface: #FCFAF6;
            --rnz-ink: #1B1A17;
            --rnz-muted: #5A564E;
            --rnz-line: #E3DACB;
        }
        body {
            font-family: 'Manrope', -apple-system, BlinkMacSystemFont, sans-serif;
            background-color: var(--rnz-ivory);
            color: var(--rnz-ink);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
        }
        .login-card {
            max-width: 430px;
            width: 100%;
            background: #FFFFFF;
            border-radius: 16px;
            box-shadow: 0 10px 30px rgba(34, 58, 45, 0.08);
            border: 1px solid var(--rnz-line);
            overflow: hidden;
        }
        .login-header {
            background-color: var(--rnz-forest);
            color: #FFFFFF;
            padding: 36px 24px 30px 24px;
            text-align: center;
            border-bottom: 2px solid var(--rnz-terracotta);
        }
        .login-header h4 {
            font-family: 'Fraunces', serif;
            letter-spacing: -0.02em;
        }
        .login-header i {
            color: var(--rnz-terracotta);
        }
        .form-control {
            border: 1px solid var(--rnz-line);
            border-radius: 8px;
            padding: 10px 14px;
            color: var(--rnz-ink);
        }
        .form-control:focus {
            border-color: var(--rnz-forest);
            box-shadow: 0 0 0 3px rgba(34, 58, 45, 0.12);
        }
        .input-group-text {
            background-color: var(--rnz-surface);
            border: 1px solid var(--rnz-line);
            color: var(--rnz-muted);
        }
        .btn-rnz {
            background-color: var(--rnz-forest);
            color: #FFFFFF;
            border: 1px solid var(--rnz-forest);
            padding: 12px;
            font-weight: 600;
            border-radius: 8px;
            transition: all 0.2s ease;
        }
        .btn-rnz:hover, .btn-rnz:focus {
            background-color: var(--rnz-forest-hover);
            border-color: var(--rnz-forest-hover);
            color: #FFFFFF;
            box-shadow: 0 4px 12px rgba(34, 58, 45, 0.25);
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
