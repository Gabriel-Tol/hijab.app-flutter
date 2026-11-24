<?php

namespace Tests\Unit;

use CodeIgniter\Test\CIUnitTestCase;
use CodeIgniter\Test\FeatureTestTrait;

final class ApiAuthAndCatalogTest extends CIUnitTestCase
{
    use FeatureTestTrait;

    protected function setUp(): void
    {
        parent::setUp();
    }

    public function testCustomerLoginReturnsJwtToken(): void
    {
        $result = $this->call('post', 'api/v1/auth/login', [
            'email'    => 'pelanggan@rnzstore.com',
            'password' => 'Nadia1234!',
        ]);

        $result->assertStatus(200);
        $json = json_decode($result->getJSON(), true);

        $this->assertTrue($json['success']);
        $this->assertNotEmpty($json['data']['token']);
        $this->assertEquals('pelanggan@rnzstore.com', $json['data']['user']['email']);
    }

    public function testGetCategoriesReturnsList(): void
    {
        $result = $this->call('get', 'api/v1/categories');

        $result->assertStatus(200);
        $json = json_decode($result->getJSON(), true);

        $this->assertTrue($json['success']);
        $this->assertIsArray($json['data']);
        $this->assertGreaterThan(0, count($json['data']));
    }

    public function testGetProductsReturnsList(): void
    {
        $result = $this->call('get', 'api/v1/products');

        $result->assertStatus(200);
        $json = json_decode($result->getJSON(), true);

        $this->assertTrue($json['success']);
        $this->assertIsArray($json['data']['products']);
        $this->assertGreaterThan(0, count($json['data']['products']));
    }

    public function testGetSettingsReturnsPaymentAndShipping(): void
    {
        $payResult = $this->call('get', 'api/v1/settings/payment-methods');
        $payResult->assertStatus(200);
        $payJson = json_decode($payResult->getJSON(), true);
        $this->assertTrue($payJson['success']);
        $this->assertGreaterThan(0, count($payJson['data']));

        $shipResult = $this->call('get', 'api/v1/settings/shipping-rates');
        $shipResult->assertStatus(200);
        $shipJson = json_decode($shipResult->getJSON(), true);
        $this->assertTrue($shipJson['success']);
        $this->assertGreaterThan(0, count($shipJson['data']));
    }

    public function testCustomerCheckoutAndCancelViaApi(): void
    {
        // 1. Login to get token
        $loginRes = $this->call('post', 'api/v1/auth/login', [
            'email'    => 'pelanggan@rnzstore.com',
            'password' => 'Nadia1234!',
        ]);
        $loginJson = json_decode($loginRes->getJSON(), true);
        $token = $loginJson['data']['token'];

        // 2. Checkout
        $checkoutData = [
            'items' => [
                ['variant_id' => 1, 'qty' => 1]
            ],
            'address' => [
                'recipient_name'  => 'Nadia Putri',
                'recipient_phone' => '081234567890',
                'province'        => 'Kalimantan Barat',
                'city'            => 'Kota Pontianak',
                'district'        => 'Pontianak Kota',
                'address_line'    => 'Jl. Gajah Mada No. 45',
                'postal_code'     => '78121',
            ],
            'payment_method' => [
                'provider'     => 'Bank BCA',
                'account_no'   => '8930123456',
                'account_name' => 'RnZ Store',
            ],
            'shipping_cost' => 10000,
        ];

        $checkoutRes = $this->withHeaders(['Authorization' => 'Bearer ' . $token])
            ->call('post', 'api/v1/orders/checkout', $checkoutData);

        $checkoutRes->assertStatus(201);
        $checkoutJson = json_decode($checkoutRes->getJSON(), true);
        $this->assertTrue($checkoutJson['success']);
        $orderId = $checkoutJson['data']['id'];

        // 3. Get Orders
        $ordersRes = $this->withHeaders(['Authorization' => 'Bearer ' . $token])
            ->call('get', 'api/v1/orders');
        $ordersRes->assertStatus(200);
        $ordersJson = json_decode($ordersRes->getJSON(), true);
        $this->assertTrue($ordersJson['success']);

        // 4. Cancel Order
        $cancelRes = $this->withHeaders(['Authorization' => 'Bearer ' . $token])
            ->call('post', "api/v1/orders/{$orderId}/cancel", ['reason' => 'Testing API cancel']);
        $cancelRes->assertStatus(200);
        $cancelJson = json_decode($cancelRes->getJSON(), true);
        $this->assertTrue($cancelJson['success']);
    }
}
