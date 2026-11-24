<?php

namespace Tests\Unit;

use CodeIgniter\Test\CIUnitTestCase;
use CodeIgniter\Test\FeatureTestTrait;

final class AdminReportTest extends CIUnitTestCase
{
    use FeatureTestTrait;

    public function testAdminReportPageLoadsWithoutOnlyFullGroupByError(): void
    {
        $sessionData = [
            'admin_logged_in' => true,
            'admin_id'        => 1,
            'admin_name'      => 'Rafly Ikhsanida (Admin)',
            'admin_email'     => 'admin@rnzstore.com',
            'admin_role'      => 'admin',
        ];

        $result = $this->withSession($sessionData)
            ->call('get', 'admin/reports');

        $result->assertStatus(200);
        $result->assertSee('Laporan Penjualan');
        $result->assertSee('Total Omzet Transaksi');
    }
}
