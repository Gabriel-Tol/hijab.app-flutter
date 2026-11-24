<?php

namespace Tests\Unit;

use CodeIgniter\Test\CIUnitTestCase;
use App\Services\OrderService;
use App\Models\VariantModel;
use App\Models\OrderModel;
use App\Models\StockMovementModel;
use Config\Database;

final class OrderServiceTest extends CIUnitTestCase
{
    protected $orderService;
    protected $variantModel;
    protected $orderModel;
    protected $stockMovementModel;

    protected function setUp(): void
    {
        parent::setUp();
        $this->orderService        = new OrderService();
        $this->variantModel        = new VariantModel();
        $this->orderModel          = new OrderModel();
        $this->stockMovementModel  = new StockMovementModel();
    }

    public function testOrderServiceClassExists(): void
    {
        $this->assertInstanceOf(OrderService::class, $this->orderService);
    }

    public function testGenerateOrderNumberFormat(): void
    {
        $orderNo = $this->orderService->generateOrderNumber();
        $this->assertMatchesRegularExpression('/^RNZ-\d{6}-\d{4}$/', $orderNo);
    }

    public function testCreateOrderDeductsStockAndCancelRestoresStock(): void
    {
        // 1. Ambil salah satu varian yang ada di database
        $variant = $this->variantModel->first();
        $this->assertNotNull($variant, 'Varian awal harus ada dari seeder');

        $initialStock = (int)$variant['stock'];
        $qtyToOrder   = 2;

        $items = [
            ['variant_id' => $variant['id'], 'qty' => $qtyToOrder]
        ];
        $address = [
            'recipient_name'  => 'Test Pembeli',
            'recipient_phone' => '08123456789',
            'address_line'    => 'Jl. Uji Coba No. 1',
            'city'            => 'Pontianak',
        ];
        $payment = [
            'provider'   => 'Bank BCA',
            'account_no' => '8930123456',
        ];

        // 2. Buat pesanan
        $order = $this->orderService->createOrder(1, $items, $address, $payment, 10000);
        $this->assertNotEmpty($order);
        $this->assertEquals('waiting_payment', $order['status']);

        // Verifikasi stok berkurang
        $updatedVariant = $this->variantModel->find($variant['id']);
        $this->assertEquals($initialStock - $qtyToOrder, (int)$updatedVariant['stock']);

        // Verifikasi mutasi stok tercatat
        $movement = $this->stockMovementModel->where('ref_order_id', $order['id'])->first();
        $this->assertNotNull($movement);
        $this->assertEquals('order', $movement['type']);
        $this->assertEquals(-$qtyToOrder, (int)$movement['qty_change']);

        // 3. Batalkan pesanan dan verifikasi stok kembali
        $cancelResult = $this->orderService->cancelOrder($order['id'], 'Pengujian pembatalan', 1);
        $this->assertTrue($cancelResult);

        $restoredVariant = $this->variantModel->find($variant['id']);
        $this->assertEquals($initialStock, (int)$restoredVariant['stock']);

        // Verifikasi mutasi pembatalan
        $cancelMovement = $this->stockMovementModel
            ->where('ref_order_id', $order['id'])
            ->where('type', 'cancel')
            ->first();
        $this->assertNotNull($cancelMovement);
        $this->assertEquals($qtyToOrder, (int)$cancelMovement['qty_change']);
    }

    public function testAdjustStockOpnameCannotBeNegative(): void
    {
        $variant = $this->variantModel->first();
        $currentStock = (int)$variant['stock'];

        // Pengurangan melebihi stok harus melempar exception
        $this->expectException(\Exception::class);
        $this->orderService->adjustStock($variant['id'], -($currentStock + 50), 'Uji stok minus', 1);
    }
}
