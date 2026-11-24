<?php

namespace App\Filters;

use CodeIgniter\Filters\FilterInterface;
use CodeIgniter\HTTP\RequestInterface;
use CodeIgniter\HTTP\ResponseInterface;
use Firebase\JWT\JWT;
use Firebase\JWT\Key;
use Exception;

class JwtAuthFilter implements FilterInterface
{
    public function before(RequestInterface $request, $arguments = null)
    {
        $authHeader = $request->getHeaderLine('Authorization');

        if (empty($authHeader) || !preg_match('/Bearer\s(\S+)/', $authHeader, $matches)) {
            $response = service('response');
            return $response->setStatusCode(401)->setJSON([
                'success' => false,
                'message' => 'Token otentikasi tidak ditemukan. Silakan login terlebih dahulu.',
            ]);
        }

        $token = trim($matches[1], "\"'");
        $jwtSecret = env('JWT_SECRET');

        if (empty($jwtSecret)) {
            $response = service('response');
            return $response->setStatusCode(500)->setJSON([
                'success' => false,
                'message' => 'Konfigurasi keamanan server (JWT_SECRET) belum disetel.',
            ]);
        }

        try {
            $decoded = JWT::decode($token, new Key($jwtSecret, 'HS256'));
            // Set user payload into request for controller access
            $request->user = $decoded;
        } catch (Exception $e) {
            $response = service('response');
            return $response->setStatusCode(401)->setJSON([
                'success' => false,
                'message' => 'Token tidak valid atau telah kedaluwarsa: ' . $e->getMessage(),
            ]);
        }
    }

    public function after(RequestInterface $request, ResponseInterface $response, $arguments = null)
    {
        // No action needed
    }
}
