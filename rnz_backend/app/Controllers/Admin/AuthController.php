<?php

namespace App\Controllers\Admin;

use App\Controllers\BaseController;
use App\Models\UserModel;

class AuthController extends BaseController
{
    protected $userModel;

    public function __construct()
    {
        $this->userModel = new UserModel();
    }

    public function login()
    {
        if (session()->get('admin_logged_in')) {
            return redirect()->to('/admin/dashboard');
        }

        return view('admin/auth/login');
    }

    public function processLogin()
    {
        $throttler = service('throttler');
        $throttleKey = md5($this->request->getIPAddress() . '_admin_login');
        if ($throttler->check($throttleKey, 5, MINUTE) === false) {
            return redirect()->back()->withInput()->with('error', 'Terlalu banyak percobaan login. Silakan tunggu 1 menit sebelum mencoba kembali.');
        }

        $rules = [
            'email'    => 'required|valid_email',
            'password' => 'required|min_length[6]',
        ];

        if (!$this->validate($rules)) {
            return redirect()->back()->withInput()->with('errors', $this->validator->getErrors());
        }

        $email    = $this->request->getPost('email');
        $password = $this->request->getPost('password');

        $user = $this->userModel->where('email', $email)->first();

        if (!$user) {
            return redirect()->back()->withInput()->with('error', 'Kombinasi email dan kata sandi salah.');
        }

        if ($user['role'] !== 'admin') {
            return redirect()->back()->withInput()->with('error', 'Akses ditolak: Hanya akun admin yang dapat masuk.');
        }

        if (!password_verify($password, $user['password_hash'])) {
            return redirect()->back()->withInput()->with('error', 'Kombinasi email dan kata sandi salah.');
        }

        if ($user['status'] !== 'active') {
            return redirect()->back()->withInput()->with('error', 'Akun Anda dinonaktifkan. Hubungi pengelola sistem.');
        }

        // Set session
        session()->set([
            'admin_logged_in' => true,
            'admin_id'        => $user['id'],
            'admin_name'      => $user['name'],
            'admin_email'     => $user['email'],
            'admin_role'      => $user['role'],
        ]);

        return redirect()->to('/admin/dashboard')->with('success', 'Selamat datang kembali, ' . $user['name'] . '!');
    }

    public function logout()
    {
        session()->destroy();
        return redirect()->to('/admin/login')->with('success', 'Anda telah berhasil keluar.');
    }
}
