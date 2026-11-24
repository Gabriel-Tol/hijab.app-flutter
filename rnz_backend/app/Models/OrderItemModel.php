<?php

namespace App\Models;

use CodeIgniter\Model;

class OrderItemModel extends Model
{
    protected $table            = 'order_items';
    protected $primaryKey       = 'id';
    protected $useAutoIncrement = true;
    protected $returnType       = 'array';
    protected $protectFields    = true;
    protected $allowedFields    = [
        'order_id',
        'variant_id',
        'product_name',
        'variant_label',
        'unit_price',
        'qty',
        'line_total'
    ];

    protected $useTimestamps = false;
}
