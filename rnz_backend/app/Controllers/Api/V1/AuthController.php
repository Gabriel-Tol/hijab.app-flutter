<?php

namespace App\Controllers\Api\V1;

use App\Controllers\Api\BaseApiController;
use App\Models\UserModel;
use Config\Database;
use Exception;

class AuthController extends BaseApiController
{
    protected $userModel;

    public function __construct()
    {
        $this->userModel = new UserModel();
    }

    public function register()
    {
        $rules = [
            'name'     => 'required|min_length[2]|max_length[100]',
            'email'    => 'required|valid_email|is_unique[users.email]',
            'phone'    => 'required|min_length[9]|max_length[20]|is_unique[users.phone]',
            'password' => 'required|min_length[6]',
        ];

        if (!$this->validate($rules)) {
            return $this->respondWithError('Validasi pendaftaran gagal', 422, $this->validator->getErrors());
        }

        $now = date('Y-m-d H:i:s');
        $userData = [
            'name'          => trim($this->request->getVar('name')),
            'email'         => trim($this->request->getVar('email')),
            'phone'         => trim($this->request->getVar('phone')),
            'password_hash' => password_hash($this->request->getVar('password'), PASSWORD_BCRYPT),
            'role'          => 'customer',
            'status'        => 'active',
            'created_at'    => $now,
            'updated_at'    => $now,
        ];

        $userId = $this->userModel->insert($userData);
        $user = $this->userModel->find($userId);
        unset($user['password_hash']);

        $token = $this->generateToken($user);

        return $this->respondWithSuccess([
            'token' => $token,
            'user'  => $user,
        ], 'Pendaftaran akun berhasil.', 201);
    }

    public function login()
    {
        $rules = [
            'email'    => 'required|valid_email',
            'password' => 'required',
        ];

        if (!$this->validate($rules)) {
            return $this->respondWithError('Email dan kata sandi wajib diisi dengan benar.', 422, $this->validator->getErrors());
        }

        $email    = trim($this->request->getVar('email'));
        $password = (string)$this->request->getVar('password');

        $user = $this->userModel->where('email', $email)->first();

        if (!$user || !password_verify($password, $user['password_hash'])) {
            return $this->respondWithError('Email atau kata sandi yang Anda masukkan salah.', 401);
        }

        if ($user['status'] !== 'active') {
            return $this->respondWithError('Akun Anda dinonaktifkan. Hubungi admin toko.', 403);
        }

        unset($user['password_hash']);
        $token = $this->generateToken($user);

        return $this->respondWithSuccess([
            'token' => $token,
            'user'  => $user,
        ], 'Login berhasil.');
    }

    public function profile()
    {
        $authUser = $this->getAuthenticatedUser();
        if (!$authUser) {
            return $this->respondWithError('Otentikasi diperlukan.', 401);
        }

        $user = $this->userModel->find($authUser->sub);
        if (!$user) {
            return $this->respondWithError('Pengguna tidak ditemukan.', 404);
        }
        unset($user['password_hash']);

        $db = Database::connect();
        $addresses = $db->table('addresses')
            ->where('user_id', $authUser->sub)
            ->orderBy('is_default', 'DESC')
            ->orderBy('id', 'DESC')
            ->get()->getResultArray();

        return $this->respondWithSuccess([
            'user'      => $user,
            'addresses' => $addresses,
        ], 'Data profil berhasil dimuat.');
    }

    public function saveAddress()
    {
        $authUser = $this->getAuthenticatedUser();
        if (!$authUser) {
            return $this->respondWithError('Otentikasi diperlukan.', 401);
        }

        $rules = [
            'label'           => 'required|max_length[50]',
            'recipient_name'  => 'required|max_length[100]',
            'recipient_phone' => 'required|min_length[9]|max_length[20]',
            'province'        => 'required|max_length[100]',
            'city'            => 'required|max_length[100]',
            'address_line'    => 'required',
            'postal_code'     => 'required|max_length[10]',
        ];

        if (!$this->validate($rules)) {
            return $this->respondWithError('Data alamat tidak lengkap.', 422, $this->validator->getErrors());
        }

        $db = Database::connect();
        $isDefault = $this->request->getVar('is_default') ? 1 : 0;

        // If default, unset previous default
        if ($isDefault) {
            $db->table('addresses')
                ->where('user_id', $authUser->sub)
                ->update(['is_default' => 0]);
        }

        $addressId = $this->request->getVar('id');
        $now = date('Y-m-d H:i:s');

        $data = [
            'user_id'         => $authUser->sub,
            'label'           => trim($this->request->getVar('label')),
            'recipient_name'  => trim($this->request->getVar('recipient_name')),
            'recipient_phone' => trim($this->request->getVar('recipient_phone')),
            'province'        => trim($this->request->getVar('province')),
            'city'            => trim($this->request->getVar('city')),
            'district'        => trim($this->request->getVar('district') ?? ''),
            'address_line'    => trim($this->request->getVar('address_line')),
            'postal_code'     => trim($this->request->getVar('postal_code')),
            'is_default'      => $isDefault,
            'updated_at'      => $now,
        ];

        if (!empty($addressId)) {
            $db->table('addresses')->where('id', $addressId)->where('user_id', $authUser->sub)->update($data);
            $saved = $db->table('addresses')->where('id', $addressId)->get()->getRowArray();
        } else {
            $data['created_at'] = $now;
            $db->table('addresses')->insert($data);
            $newId = $db->insertID();
            $saved = $db->table('addresses')->where('id', $newId)->get()->getRowArray();
        }

        return $this->respondWithSuccess($saved, 'Alamat pengiriman berhasil disimpan.');
    }
}
