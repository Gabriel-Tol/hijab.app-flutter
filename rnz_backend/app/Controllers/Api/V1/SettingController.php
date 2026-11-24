<?php

namespace App\Controllers\Api\V1;

use App\Controllers\Api\BaseApiController;
use App\Models\PaymentMethodModel;
use App\Models\ShippingRateModel;

class SettingController extends BaseApiController
{
    protected $paymentModel;
    protected $shippingModel;

    public function __construct()
    {
        $this->paymentModel  = new PaymentMethodModel();
        $this->shippingModel = new ShippingRateModel();
    }

    public function getPaymentMethods()
    {
        $methods = $this->paymentModel->where('is_active', 1)->orderBy('id', 'ASC')->findAll();
        return $this->respondWithSuccess($methods, 'Metode pembayaran aktif berhasil dimuat.');
    }

    public function getShippingRates()
    {
        $rates = $this->shippingModel->where('is_active', 1)->orderBy('cost', 'ASC')->findAll();
        foreach ($rates as &$r) {
            $r['cost'] = (int)$r['cost'];
        }
        return $this->respondWithSuccess($rates, 'Tarif pengiriman aktif berhasil dimuat.');
    }
}
