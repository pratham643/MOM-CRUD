<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>View Employee</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
</head>
<body>
    <div class="container mt-5">
        <h1 class="mb-4">Employee Details</h1>
        
        <div class="card">
            <div class="card-body">
                <h5 class="card-title">{{ $employee->name }}</h5>
                <p class="card-text">
                    <strong>Email:</strong> {{ $employee->email }}<br>
                    <strong>Department:</strong> {{ $employee->department }}<br>
                    <strong>Designation:</strong> {{ $employee->designation }}<br>
                    <strong>Salary:</strong> {{ $employee->salary }}<br>
                    <strong>Joining Date:</strong> {{ $employee->joining_date }}<br>
                    <strong>Created At:</strong> {{ $employee->created_at }}<br>
                    <strong>Updated At:</strong> {{ $employee->updated_at }}
                </p>
                <a href="{{ route('employees.index') }}" class="btn btn-secondary">Back</a>
                <a href="{{ route('employees.edit', $employee->id) }}" class="btn btn-warning">Edit</a>
            </div>
        </div>
    </div>
</body>
</html>
