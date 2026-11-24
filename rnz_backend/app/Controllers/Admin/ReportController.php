<?php

namespace App\Controllers\Admin;

use App\Controllers\BaseController;
use Config\Database;
use Dompdf\Dompdf;
use Dompdf\Options;

class ReportController extends BaseController
{
    public function index()
    {
        $startDate = $this->request->getGet('start_date') ?? date('Y-m-01');
        $endDate   = $this->request->getGet('end_date') ?? date('Y-m-d');

        $data = $this->getReportData($startDate, $endDate);
        $data['title']     = 'Laporan Penjualan';
        $data['startDate'] = $startDate;
        $data['endDate']   = $endDate;

        return view('admin/reports/index', $data);
    }

    public function exportPdf()
    {
        $startDate = $this->request->getGet('start_date') ?? date('Y-m-01');
        $endDate   = $this->request->getGet('end_date') ?? date('Y-m-d');

        $data = $this->getReportData($startDate, $endDate);
        $data['title']     = 'Laporan Rekapitulasi Penjualan RnZ Store';
        $data['startDate'] = $startDate;
        $data['endDate']   = $endDate;
        $data['printedAt'] = date('d F Y, H:i');

        $html = view('admin/reports/pdf_template', $data);

        $options = new Options();
        $options->set('isRemoteEnabled', true);
        $options->set('defaultFont', 'Helvetica');

        $dompdf = new Dompdf($options);
        $dompdf->loadHtml($html);
        $dompdf->setPaper('A4', 'portrait');
        $dompdf->render();

        $filename = 'Laporan-Penjualan-RnZ-' . date('Ymd', strtotime($startDate)) . '-sd-' . date('Ymd', strtotime($endDate)) . '.pdf';
        return $this->response
            ->setHeader('Content-Type', 'application/pdf')
            ->setHeader('Content-Disposition', 'attachment; filename="' . $filename . '"')
            ->setBody($dompdf->output());
    }

    private function getReportData(string $startDate, string $endDate): array
    {
        $db = Database::connect();
        $start = $startDate . ' 00:00:00';
        $end   = $endDate . ' 23:59:59';

        // 1. Daftar pesanan yang berhasil (processing, shipped, completed)
        $orders = $db->table('orders')
            ->select('orders.*, users.name as customer_name')
            ->join('users', 'users.id = orders.user_id')
            ->whereIn('orders.status', ['processing', 'shipped', 'completed'])
            ->where('orders.created_at >=', $start)
            ->where('orders.created_at <=', $end)
            ->orderBy('orders.id', 'DESC')
            ->get()->getResultArray();

        $totalRevenue    = 0;
        $totalItemsCount = 0;

        foreach ($orders as $o) {
            $totalRevenue += (int)$o['total'];
        }

        // 2. Produk terlaris pada rentang waktu
        $topProducts = $db->table('order_items')
            ->select('order_items.product_name, order_items.variant_label, SUM(order_items.qty) as total_qty, SUM(order_items.line_total) as total_amount')
            ->join('orders', 'orders.id = order_items.order_id')
            ->whereIn('orders.status', ['processing', 'shipped', 'completed'])
            ->where('orders.created_at >=', $start)
            ->where('orders.created_at <=', $end)
            ->groupBy(['order_items.variant_id', 'order_items.product_name', 'order_items.variant_label'])
            ->orderBy('total_qty', 'DESC')
            ->limit(5)
            ->get()->getResultArray();

        foreach ($topProducts as $tp) {
            $totalItemsCount += (int)$tp['total_qty'];
        }

        return [
            'orders'          => $orders,
            'totalRevenue'    => $totalRevenue,
            'orderCount'      => count($orders),
            'topProducts'     => $topProducts,
            'totalItemsCount' => $totalItemsCount,
        ];
    }
}
