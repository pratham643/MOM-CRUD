<?php

namespace Tests\Feature;

use App\Models\Employee;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class EmployeeTest extends TestCase
{
    use RefreshDatabase;

    public function test_can_create_employee_with_valid_data(): void
    {
        $payload = $this->validPayload();

        $response = $this->post(route('employees.store'), $payload);

        $response
            ->assertRedirect(route('employees.index'))
            ->assertSessionHas('success', 'Employee created successfully.');

        $this->assertDatabaseHas('employees', [
            'name' => $payload['name'],
            'email' => $payload['email'],
            'department' => $payload['department'],
            'designation' => $payload['designation'],
            'manager' => $payload['manager'],
        ]);
    }

    public function test_cannot_create_employee_with_invalid_data(): void
    {
        $response = $this
            ->from(route('employees.create'))
            ->post(route('employees.store'), [
                'name' => '',
                'email' => 'not-an-email',
                'department' => '',
                'designation' => '',
                'salary' => -1,
                'joining_date' => 'not-a-date',
                'manager' => '',
            ]);

        $response
            ->assertRedirect(route('employees.create'))
            ->assertSessionHasErrors([
                'name',
                'email',
                'department',
                'designation',
                'salary',
                'joining_date',
                'manager',
            ]);

        $this->assertDatabaseCount('employees', 0);
    }

    public function test_create_employee_rejects_duplicate_email(): void
    {
        Employee::factory()->create(['email' => 'duplicate@example.com']);

        $response = $this
            ->from(route('employees.create'))
            ->post(route('employees.store'), $this->validPayload([
                'email' => 'duplicate@example.com',
            ]));

        $response
            ->assertRedirect(route('employees.create'))
            ->assertSessionHasErrors('email');

        $this->assertDatabaseCount('employees', 1);
    }

    public function test_can_read_employee_list_and_detail_pages(): void
    {
        $employee = Employee::factory()->create([
            'name' => 'Ada Lovelace',
            'email' => 'ada@example.com',
        ]);

        $this->get(route('employees.index'))
            ->assertOk()
            ->assertViewIs('employees.index')
            ->assertSee('Ada Lovelace')
            ->assertSee('ada@example.com');

        $this->get(route('employees.show', $employee))
            ->assertOk()
            ->assertViewIs('employees.show')
            ->assertSee('Ada Lovelace')
            ->assertSee('ada@example.com');
    }

    public function test_can_update_employee_with_valid_data(): void
    {
        $employee = Employee::factory()->create([
            'email' => 'old@example.com',
            'salary' => 50000,
        ]);

        $payload = $this->validPayload([
            'name' => 'Updated Employee',
            'email' => 'updated@example.com',
            'department' => 'Finance',
            'designation' => 'Senior Analyst',
            'salary' => 95000,
            'manager' => 'Grace Hopper',
        ]);

        $response = $this->put(route('employees.update', $employee), $payload);

        $response
            ->assertRedirect(route('employees.index'))
            ->assertSessionHas('success', 'Employee updated successfully.');

        $this->assertDatabaseHas('employees', [
            'id' => $employee->id,
            'name' => 'Updated Employee',
            'email' => 'updated@example.com',
            'department' => 'Finance',
            'designation' => 'Senior Analyst',
            'salary' => '95000.00',
            'manager' => 'Grace Hopper',
        ]);
    }

    public function test_update_employee_returns_validation_errors(): void
    {
        $employee = Employee::factory()->create();
        $otherEmployee = Employee::factory()->create(['email' => 'taken@example.com']);

        $response = $this
            ->from(route('employees.edit', $employee))
            ->put(route('employees.update', $employee), [
                'name' => '',
                'email' => $otherEmployee->email,
                'department' => '',
                'designation' => '',
                'salary' => 'abc',
                'joining_date' => 'wrong',
                'manager' => '',
            ]);

        $response
            ->assertRedirect(route('employees.edit', $employee))
            ->assertSessionHasErrors([
                'name',
                'email',
                'department',
                'designation',
                'salary',
                'joining_date',
                'manager',
            ]);
    }

    public function test_can_delete_employee(): void
    {
        $employee = Employee::factory()->create();

        $response = $this->delete(route('employees.destroy', $employee));

        $response
            ->assertRedirect(route('employees.index'))
            ->assertSessionHas('success', 'Employee deleted successfully.');

        $this->assertDatabaseMissing('employees', [
            'id' => $employee->id,
        ]);
    }

    private function validPayload(array $overrides = []): array
    {
        return array_merge([
            'name' => 'John Doe',
            'email' => 'john@example.com',
            'department' => 'Engineering',
            'designation' => 'Software Engineer',
            'salary' => 75000.50,
            'joining_date' => '2026-05-04',
            'manager' => 'Jane Smith',
        ], $overrides);
    }
}
