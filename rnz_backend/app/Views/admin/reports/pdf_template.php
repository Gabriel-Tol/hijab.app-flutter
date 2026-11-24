<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title><?= esc($title) ?></title>
    <style>
        body {
            font-family: Helvetica, Arial, sans-serif;
            font-size: 11px;
            color: #333333;
            line-height: 1.4;
        }
        .header {
            text-align: center;
            border-bottom: 2px solid #223A2D;
            padding-bottom: 12px;
            margin-bottom: 20px;
        }
        .header h2 {
            margin: 0;
            color: #223A2D;
            font-size: 18px;
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }
        .header p {
            margin: 4px 0 0 0;
            color: #5A564E;
            font-size: 10px;
        }
        .meta-info {
            margin-bottom: 15px;
        }
        .meta-info table {
            width: 100%;
        }
        .meta-info td {
            font-size: 11px;
            padding: 2px 0;
            color: #1B1A17;
        }
        .summary-box {
            background-color: #F7F2E9;
            border: 1px solid #E3DACB;
            padding: 12px 16px;
            margin-bottom: 18px;
        }
        .summary-box table {
            width: 100%;
        }
        .summary-box td {
            vertical-align: middle;
        }
        .summary-title {
            font-size: 10px;
            color: #5A564E;
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }
        .summary-value {
            font-size: 15px;
            font-weight: bold;
            color: #223A2D;
        }
        table.data-table {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 20px;
        }
        table.data-table th {
            background-color: #223A2D;
            color: #ffffff;
            font-weight: bold;
            text-align: left;
            padding: 6px 8px;
            font-size: 10px;
        }
        table.data-table td {
            border-bottom: 1px solid #E3DACB;
            padding: 6px 8px;
            font-size: 10px;
            color: #1B1A17;
        }
        table.data-table tr:nth-child(even) {
            background-color: #FCFAF6;
        }
        .text-center {
            text-align: center;
        }
        .text-right {
            text-align: right;
        }
        .footer {
            margin-top: 30px;
            border-top: 1px solid #E3DACB;
            padding-top: 8px;
            font-size: 9px;
            color: #8E9F94;
            text-align: right;
        }
    </style>
</head>
<body>
    <div class="header">
        <h2>RnZ Store Pontianak</h2>
        <p>Laporan Rekapitulasi Penjualan & Transaksi Toko Hijab</p>
    </div>

    <div class="meta-info">
        <table>
            <tr>
                <td style="width: 50%;"><strong>Periode Laporan:</strong> <?= date('d M Y', strtotime($startDate)) ?> s/d <?= date('d M Y', strtotime($endDate)) ?></td>
                <td style="width: 50%;" class="text-right"><strong>Waktu Cetak:</strong> <?= esc($printedAt) ?> WIB</td>
            </tr>
        </table>
    </div>

    <div class="summary-box">
        <table>
            <tr>
                <td style="width: 50%;">
                    <div class="summary-title">Total Omzet Penjualan</div>
                    <div class="summary-value" style="color: #C06B4E;">Rp <?= number_format($totalRevenue, 0, ',', '.') ?></div>
                </td>
                <td style="width: 50%;" class="text-right">
                    <div class="summary-title">Jumlah Transaksi Berhasil</div>
                    <div class="summary-value"><?= $orderCount ?> Pesanan</div>
                </td>
            </tr>
        </table>
    </div>

    <!-- Tabel Top Produk -->
    <?php if (!empty($topProducts)): ?>
        <h4 style="margin: 0 0 8px 0; font-size: 11px; color: #2d3748;">Produk Terlaris</h4>
        <table class="data-table" style="margin-bottom: 15px;">
            <thead>
                <tr>
                    <th style="width: 35px;" class="text-center">#</th>
                    <th>Nama Produk Hijab</th>
                    <th>Varian</th>
                    <th class="text-center" style="width: 70px;">Terjual</th>
                    <th class="text-right" style="width: 100px;">Total Nominal</th>
                </tr>
            </thead>
            <tbody>
                <?php foreach ($topProducts as $idx => $tp): ?>
                    <tr>
                        <td class="text-center"><?= $idx + 1 ?></td>
                        <td><?= esc($tp['product_name']) ?></td>
                        <td><?= esc($tp['variant_label']) ?></td>
                        <td class="text-center"><strong><?= $tp['total_qty'] ?></strong> pcs</td>
                        <td class="text-right">Rp <?= number_format($tp['total_amount'], 0, ',', '.') ?></td>
                    </tr>
                <?php endforeach; ?>
            </tbody>
        </table>
    <?php endif; ?>

    <!-- Tabel Rincian Pesanan -->
    <h4 style="margin: 0 0 8px 0; font-size: 11px; color: #2d3748;">Daftar Transaksi</h4>
    <table class="data-table">
        <thead>
            <tr>
                <th style="width: 25px;" class="text-center">#</th>
                <th style="width: 90px;">No. Pesanan</th>
                <th style="width: 75px;">Tanggal</th>
                <th>Nama Pelanggan</th>
                <th class="text-right" style="width: 70px;">Subtotal</th>
                <th class="text-right" style="width: 55px;">Ongkir</th>
                <th class="text-right" style="width: 75px;">Total</th>
            </tr>
        </thead>
        <tbody>
            <?php if (empty($orders)): ?>
                <tr>
                    <td colspan="7" class="text-center" style="padding: 20px;">Tidak ada transaksi berhasil pada periode ini.</td>
                </tr>
            <?php else: ?>
                <?php foreach ($orders as $index => $o): ?>
                    <tr>
                        <td class="text-center"><?= $index + 1 ?></td>
                        <td><strong><?= esc($o['order_no']) ?></strong></td>
                        <td><?= date('d/m/Y', strtotime($o['created_at'])) ?></td>
                        <td><?= esc($o['customer_name']) ?></td>
                        <td class="text-right">Rp <?= number_format($o['subtotal'], 0, ',', '.') ?></td>
                        <td class="text-right">Rp <?= number_format($o['shipping_cost'], 0, ',', '.') ?></td>
                        <td class="text-right"><strong>Rp <?= number_format($o['total'], 0, ',', '.') ?></strong></td>
                    </tr>
                <?php endforeach; ?>
            <?php endif; ?>
        </tbody>
    </table>

    <div class="footer">
        Dicetak otomatis oleh Sistem E-Commerce RnZ Store • Halaman 1
    </div>
</body>
</html>
