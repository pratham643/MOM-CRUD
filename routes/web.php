<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\EmployeeController;

Route::get('/', function () {
    return redirect('/employees');
});

Route::resource('employees', EmployeeController::class);