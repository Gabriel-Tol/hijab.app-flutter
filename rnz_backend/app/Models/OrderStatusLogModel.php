<?php

namespace App\Models;

use CodeIgniter\Model;

class OrderStatusLogModel extends Model
{
    protected $table            = 'order_status_logs';
    protected $primaryKey       = 'id';
    protected $useAutoIncrement = true;
    protected $returnType       = 'array';
    protected $protectFields    = true;
    protected $allowedFields    = [
        'order_id',
        'from_status',
        'to_status',
        'note',
        'actor_id',
        'created_at'
    ];

    protected $useTimestamps = false;
}
