# Data Migration & Schema Import

## Schema Analysis

### 1. Analyze Source Schema

```bash
# For MySQL
mysqldump -u root -p database --no-data > schema.sql

# For PostgreSQL
pg_dump -s database > schema.sql

# For SQLite
.schema > schema.sql
```

### 2. Map to Laravel Conventions

| Source Pattern | Laravel Convention | Notes |
|---|---|---|
| `user_id` | Foreign key reference | Use Model relationships |
| Indexes | Schema blueprint | Define in migrations |
| Constraints | Foreign keys | Define with cascades |
| Defaults | Column definition | Set in migrations |

## Creating Migrations from Schema

### Using Illuminate Generator

```bash
php artisan make:migration create_users_table

# Then populate manually based on source schema
```

### Example Migration

```php
Schema::create('users', function (Blueprint $table) {
    $table->id();
    $table->string('name');
    $table->string('email')->unique();
    $table->timestamp('email_verified_at')->nullable();
    $table->string('password');
    $table->rememberToken();
    $table->timestamps();
    
    // Indexes from source schema
    $table->index('email');
    $table->index('created_at');
});
```

## Data Transformation Pipeline

### 1. Export Source Data

```bash
# MySQL
mysqldump -u root -p database --tab=/tmp --fields-terminated-by=','

# PostgreSQL
\COPY table TO 'data.csv' WITH CSV HEADER

# Generic SQL
SELECT * FROM table INTO OUTFILE 'data.csv'
```

### 2. Transform & Clean

```php
// Create action for data transformation
class ImportUsersAction {
    public function execute(iterable $rows): void {
        foreach ($rows as $row) {
            User::create([
                'name' => $row['full_name'] ?? '',
                'email' => strtolower(trim($row['email'])),
                'password' => Hash::make(bin2hex(random_bytes(8))),
                'created_at' => $this->parseDate($row['created']),
            ]);
        }
    }
    
    private function parseDate(?string $date): ?Carbon {
        return $date ? Carbon::parse($date) : null;
    }
}
```

### 3. Validate Data

```php
// Before import
foreach ($sourceData as $row) {
    $this->validate($row, [
        'email' => 'required|email|unique:users',
        'name' => 'required|string',
    ]);
}

// Reject invalid rows, log for manual review
```

### 4. Import in Batches

```php
collect($sourceData)
    ->chunk(500)
    ->each(function ($chunk) {
        DB::transaction(function () use ($chunk) {
            foreach ($chunk as $row) {
                User::create($row);
            }
        });
    });
```

## Handling Foreign Keys & Relationships

### Preserve Relationships

```php
// Map old IDs to new IDs during import
$idMap = [];

// First pass: create users
foreach ($sourceData as $row) {
    $user = User::create([...]);
    $idMap[$row['id']] = $user->id;
}

// Second pass: create related data using mapped IDs
foreach ($sourceOrders as $order) {
    Order::create([
        'user_id' => $idMap[$order['user_id']],
        // ...
    ]);
}
```

### Enable Constraints After Import

```php
// Disable during import
DB::statement('SET FOREIGN_KEY_CHECKS=0');

// Import data...

// Re-enable and verify
DB::statement('SET FOREIGN_KEY_CHECKS=1');
DB::statement('CHECK TABLE users');
```

## Post-Import Validation

```bash
# Count records
php artisan tinker
>>> User::count()

# Verify data integrity
>>> User::where('email', null)->count()
>>> User::whereDate('created_at', '<', '2020-01-01')->count()

# Check relationships
>>> User::doesntHave('orders')->count()
```

## Rollback & Cleanup

```bash
# If import fails
Schema::drop('users');
DB::table('failed_imports')->insert($failedRows);

# Or restore from backup
php artisan backup:restore --source=local
```
