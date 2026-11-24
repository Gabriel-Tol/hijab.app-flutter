<?php

namespace App\Models;

use CodeIgniter\Model;

class PaymentProofModel extends Model
{
    protected $table            = 'payment_proofs';
    protected $primaryKey       = 'id';
    protected $useAutoIncrement = true;
    protected $returnType       = 'array';
    protected $protectFields    = true;
    protected $allowedFields    = [
        'order_id',
        'file_path',
        'status',
        'reject_reason',
        'reviewed_by',
        'reviewed_at',
        'created_at'
    ];

    protected $useTimestamps = false;
}
