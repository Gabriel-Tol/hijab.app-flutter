<?php

namespace App\Controllers\Api;

use App\Controllers\BaseController;
use CodeIgniter\HTTP\ResponseInterface;
use Firebase\JWT\JWT;

class BaseApiController extends BaseController
{
    protected function respondWithSuccess($data = null, string $message = 'Operasi berhasil', int $statusCode = 200): ResponseInterface
    {
        $payload = [
            'success' => true,
            'message' => $message,
            'data'    => $data,
        ];
        return $this->response->setStatusCode($statusCode)->setJSON($payload);
    }

    protected function respondWithError(string $message = 'Terjadi kesalahan', int $statusCode = 400, $errors = null): ResponseInterface
    {
        $payload = [
            'success' => false,
            'message' => $message,
        ];
        if ($errors !== null) {
            $payload['errors'] = $errors;
        }
        return $this->response->setStatusCode($statusCode)->setJSON($payload);
    }

    protected function generateToken(array $user): string
    {
        $secret = env('JWT_SECRET', 'rnz_store_secret_jwt_key_2026_super_secure_key_for_pontianak_hijab');
        $now = time();
        $payload = [
            'iss'   => 'rnz_store_backend',
            'iat'   => $now,
            'exp'   => $now + (30 * 24 * 60 * 60), // 30 days
            'sub'   => (int)$user['id'],
            'email' => $user['email'],
            'name'  => $user['name'],
            'role'  => $user['role'],
        ];

        return JWT::encode($payload, $secret, 'HS256');
    }

    protected function getAuthenticatedUser(): ?object
    {
        return $this->request->user ?? null;
    }
}
