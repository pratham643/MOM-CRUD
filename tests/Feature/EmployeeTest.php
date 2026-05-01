<?php

namespace Tests\Feature;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class EmployeeTest extends TestCase
{
    use RefreshDatabase;

    public function test_employee_can_be_created(): void
    {
        $response = $this->post('/employees', [
            'name' => 'Test Employee',
            'email' => 'test.employee@example.com',
            'department' => 'Engineering',
            'designation' => 'Developer',
            'salary' => '50000.00',
            'joining_date' => '2026-05-01',
        ]);

        $response->assertRedirect('/employees');

        $this->assertDatabaseHas('employees', [
            'name' => 'Test Employee',
            'email' => 'test.employee@example.com',
            'department' => 'Engineering',
            'designation' => 'Developer',
            'joining_date' => '2026-05-01 00:00:00',
        ]);
    }
}
