<?php

namespace App\Models;

use CodeIgniter\Model;

class StockMovementModel extends Model
{
    protected $table            = 'stock_movements';
    protected $primaryKey       = 'id';
    protected $useAutoIncrement = true;
    protected $returnType       = 'array';
    protected $protectFields    = true;
    protected $allowedFields    = [
        'variant_id',
        'type',
        'qty_change',
        'stock_before',
        'stock_after',
        'reason',
        'ref_order_id',
        'admin_id',
        'created_at'
    ];

    protected $useTimestamps = false;
}
