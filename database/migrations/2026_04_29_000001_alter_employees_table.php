<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('employees', function (Blueprint $table) {
            // Add new columns instead of dropping non-existent ones
            $table->string('email')->unique()->after('name');
            $table->string('department')->after('email');
            $table->string('designation')->after('department');
            $table->decimal('salary', 10, 2)->after('designation');
            $table->date('joining_date')->after('salary');
        });
    }

    public function down(): void
    {
        Schema::table('employees', function (Blueprint $table) {
            $table->dropColumn(['email', 'department', 'designation', 'salary', 'joining_date']);
        });
    }
};