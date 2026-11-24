<?php

namespace App\Controllers\Admin;

use App\Controllers\BaseController;
use App\Models\PaymentMethodModel;
use App\Models\ShippingRateModel;

class SettingController extends BaseController
{
    protected $paymentModel;
    protected $shippingModel;

    public function __construct()
    {
        $this->paymentModel  = new PaymentMethodModel();
        $this->shippingModel = new ShippingRateModel();
    }

    public function index()
    {
        $paymentMethods = $this->paymentModel->orderBy('id', 'ASC')->findAll();
        $shippingRates  = $this->shippingModel->orderBy('id', 'ASC')->findAll();

        $data = [
            'title'          => 'Pengaturan Toko',
            'paymentMethods' => $paymentMethods,
            'shippingRates'  => $shippingRates,
        ];

        return view('admin/settings/index', $data);
    }

    public function storePaymentMethod()
    {
        $type        = $this->request->getPost('type');
        $provider    = trim($this->request->getPost('provider'));
        $accountNo   = trim($this->request->getPost('account_no'));
        $accountName = trim($this->request->getPost('account_name'));

        if (empty($provider) || empty($accountNo) || empty($accountName)) {
            return redirect()->back()->with('error', 'Semua kolom metode pembayaran wajib diisi.');
        }

        $this->paymentModel->insert([
            'type'         => $type,
            'provider'     => $provider,
            'account_no'   => $accountNo,
            'account_name' => $accountName,
            'is_active'    => $this->request->getPost('is_active') ? 1 : 0,
        ]);

        return redirect()->to('/admin/settings')->with('success', 'Metode pembayaran berhasil ditambahkan.');
    }

    public function updatePaymentMethod($id)
    {
        $method = $this->paymentModel->find($id);
        if (!$method) {
            return redirect()->back()->with('error', 'Metode pembayaran tidak ditemukan.');
        }

        $this->paymentModel->update($id, [
            'type'         => $this->request->getPost('type'),
            'provider'     => trim($this->request->getPost('provider')),
            'account_no'   => trim($this->request->getPost('account_no')),
            'account_name' => trim($this->request->getPost('account_name')),
            'is_active'    => $this->request->getPost('is_active') ? 1 : 0,
        ]);

        return redirect()->to('/admin/settings')->with('success', 'Metode pembayaran berhasil diperbarui.');
    }

    public function deletePaymentMethod($id)
    {
        $this->paymentModel->delete($id);
        return redirect()->to('/admin/settings')->with('success', 'Metode pembayaran berhasil dihapus.');
    }

    public function storeShippingRate()
    {
        $regionName = trim($this->request->getPost('region_name'));
        $cost       = (int)$this->request->getPost('cost');

        if (empty($regionName) || $cost < 0) {
            return redirect()->back()->with('error', 'Nama wilayah dan tarif ongkir wajib diisi.');
        }

        $this->shippingModel->insert([
            'region_name' => $regionName,
            'cost'        => $cost,
            'is_active'   => $this->request->getPost('is_active') ? 1 : 0,
        ]);

        return redirect()->to('/admin/settings')->with('success', 'Tarif ongkir wilayah berhasil ditambahkan.');
    }

    public function updateShippingRate($id)
    {
        $rate = $this->shippingModel->find($id);
        if (!$rate) {
            return redirect()->back()->with('error', 'Tarif wilayah tidak ditemukan.');
        }

        $this->shippingModel->update($id, [
            'region_name' => trim($this->request->getPost('region_name')),
            'cost'        => (int)$this->request->getPost('cost'),
            'is_active'   => $this->request->getPost('is_active') ? 1 : 0,
        ]);

        return redirect()->to('/admin/settings')->with('success', 'Tarif ongkir wilayah berhasil diperbarui.');
    }

    public function deleteShippingRate($id)
    {
        $this->shippingModel->delete($id);
        return redirect()->to('/admin/settings')->with('success', 'Tarif ongkir wilayah berhasil dihapus.');
    }
}
