<?php

namespace Database\Factories;

use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends \Illuminate\Database\Eloquent\Factories\Factory<\App\Models\Employee>
 */
class EmployeeFactory extends Factory
{
    /**
     * Define the model's default state.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'name' => $this->faker->name(),
            'email' => $this->faker->unique()->safeEmail(),
            'department' => $this->faker->randomElement(['IT', 'HR', 'Finance', 'Sales', 'Operations']),
            'designation' => $this->faker->randomElement(['Manager', 'Developer', 'Designer', 'Analyst', 'Coordinator']),
            'salary' => $this->faker->numberBetween(30000, 150000),
            'joining_date' => $this->faker->date(),
            'manager' => $this->faker->name(),
        ];
    }
}
