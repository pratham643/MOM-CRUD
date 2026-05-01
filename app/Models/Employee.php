<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Employee extends Model
{
    protected $fillable = [
        'name',
        'email',
        'department',
        'designation',
        'salary',
        'joining_date',
    ];
}
