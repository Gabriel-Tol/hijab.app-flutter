@echo off
title RnZ Store - Server & Cloudflare Tunnel Online

echo ======================================================================
echo           RnZ STORE - BACKEND CODEIGNITER 4 ^& CLOUDFLARE TUNNEL
echo ======================================================================
echo.

cd /d "%~dp0"

echo [1/3] Memeriksa binary Cloudflare Tunnel (cloudflared.exe)...
if not exist "bin\cloudflared.exe" (
    echo [INFO] Mengunduh cloudflared.exe otomatis...
    curl.exe -L -o "bin\cloudflared.exe" https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-windows-amd64.exe
)

echo [2/3] Menjalankan CodeIgniter 4 Development Server di port 8080...
start "RnZ Backend Server (Port 8080)" cmd /k "php spark serve --port 8080"
timeout /t 2 /nobreak >nul

echo [3/3] Membuka Cloudflare Tunnel publik gratis ke port 8080...
echo.
echo ======================================================================
echo PERHATIAN:
echo Salin URL HTTPS yang muncul di bawah (contoh: https://xxx.trycloudflare.com)
echo dan gunakan sebagai URL API backend di aplikasi Flutter:
echo.
echo - Web Admin:      https://xxx.trycloudflare.com/admin/login
echo - REST API:       https://xxx.trycloudflare.com/api/v1/
echo - Jalankan Flutter: flutter run --dart-define=API_BASE_URL=https://xxx.trycloudflare.com
echo ======================================================================
echo.

bin\cloudflared.exe tunnel --url http://localhost:8080
pause
