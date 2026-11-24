<?php

namespace App\Models;

use CodeIgniter\Model;

class VariantModel extends Model
{
    protected $table            = 'product_variants';
    protected $primaryKey       = 'id';
    protected $useAutoIncrement = true;
    protected $returnType       = 'array';
    protected $useSoftDeletes   = false;
    protected $protectFields    = true;
    protected $allowedFields    = [
        'product_id',
        'color',
        'size',
        'sku',
        'stock',
        'is_active'
    ];

    protected $useTimestamps = true;
    protected $createdField  = 'created_at';
    protected $updatedField  = 'updated_at';

    protected $validationRules = [
        'product_id' => 'required|is_natural_no_zero',
        'color'      => 'required|max_length[50]',
        'stock'      => 'required|integer',
    ];
}
