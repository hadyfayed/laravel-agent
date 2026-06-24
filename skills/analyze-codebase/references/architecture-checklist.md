# Architecture Assessment Checklist

## Project Structure

### Standard Laravel structure
- `app/` — Application code
  - `Console/` — Artisan commands
  - `Http/` — Controllers, Middleware, Requests, Resources
  - `Models/` — Eloquent models
  - `Providers/` — Service providers
  - `Jobs/` — Queued jobs
  - `Events/`, `Listeners/` — Event system
  - `Mail/` — Mailable classes
  - `Notifications/` — Notification classes
  - `Policies/` — Authorization policies
  - `Exceptions/` — Exception handlers

### Domain-Driven structure
- `src/` — Domain layers
  - `Domain/` — Business logic, entities, value objects
  - `Application/` — Use cases, services
  - `Infrastructure/` — Repositories, external integrations
  - `UI/` — Controllers, views (API/Web)

### Feature/Module structure
- `app/Features/<FeatureName>/`
  - `Models/`, `Controllers/`, `Jobs/`, `Events/`, `Tests/`

## Separation of Concerns

### Controllers
- ✅ Thin controllers (≤15 lines per action ideally)
- ✅ No business logic in controllers
- ✅ Use FormRequest for validation
- ✅ Use Action/Service classes for complex flows

### Models
- ✅ Relationship definitions
- ✅ Scopes for query encapsulation
- ✅ Mutators/Accessors for transformations
- ❌ Business logic (move to Services/Actions)
- ❌ Heavy queries (move to Repositories/Scopes)

### Services
- ✅ Encapsulate business logic
- ✅ Reusable across controllers/jobs
- ✅ Testable in isolation
- ✅ Constructor injection of dependencies

### Repositories (optional pattern)
- ✅ Encapsulate query logic
- ✅ Abstract database implementation
- ✅ Enable easy swapping of storage backends

## SOLID Principles

### Single Responsibility Principle
- One class should have one reason to change
- ❌ Auth controller handling validation AND payment processing
- ✅ Separate PaymentService, validation in FormRequest

### Open/Closed Principle
- Open for extension, closed for modification
- ✅ Use interfaces and abstract classes
- ✅ Composition over inheritance
- ❌ Modifying existing classes to add features

### Liskov Substitution Principle
- Subclasses must be substitutable for base classes
- ✅ All Payment drivers implement PaymentGateway interface identically
- ❌ SMS driver breaks email driver contract

### Interface Segregation Principle
- Clients should not depend on interfaces they don't use
- ✅ Separate UserRepositoryRead and UserRepositoryWrite interfaces
- ❌ One huge Repository interface with 50 methods

### Dependency Inversion Principle
- Depend on abstractions, not concretions
- ✅ Inject interfaces/contracts
- ❌ Inject concrete classes directly
- ✅ Use service container for resolution

## Design Patterns

### Repository Pattern
- Encapsulates query logic
- Enables easy testing (swap with in-memory repo)
- Reduces coupling to Eloquent

### Service/Action Pattern
- Encapsulates business logic
- Single responsibility
- Reusable across controllers/jobs

### Observer/Event Pattern
- Decouples listeners from event source
- Enables cross-cutting concerns (logging, notifications)
- Config in `app/Providers/EventServiceProvider.php`

### Strategy Pattern
- Multiple algorithms for same problem
- Used for payment gateways, export formats, etc.

### Factory Pattern
- Centralize object creation
- Service providers configure factories

## Dependency Injection

### Constructor Injection (preferred)
```php
class OrderService {
    public function __construct(
        private UserRepository $users,
        private PaymentGateway $payment
    ) {}
}
```

### Method Injection (for optional dependencies)
```php
public function process(Logger $log = null) {
    $log ??= Log::channel('default');
}
```

### Property Injection (avoid)
```php
$service->logger = Log::channel('default');  // BAD
```

## Naming Consistency

### Classes
- ✅ `PascalCase` — `OrderService`, `UserRepository`
- ❌ `snake_case` — `order_service`, `user_repository`

### Methods
- ✅ `camelCase` — `getUserOrders()`, `markAsProcessed()`
- ❌ `PascalCase` — `GetUserOrders()`, `MarkAsProcessed()`

### Variables
- ✅ `camelCase` — `$activeUsers`, `$totalAmount`
- ✅ `$user_id` acceptable for database columns

### Directories
- ✅ `PascalCase` — `app/Http/Controllers/`, `app/Services/`
- ✅ `snake_case` acceptable for features — `app/Features/user_management/`

## Type Hinting

### Method signatures
- ✅ Type hints on parameters and return types
```php
public function getOrder(int $id): Order
```

### Union types (PHP 8.0+)
- ✅ Multiple possible types
```php
public function process(Order|Invoice $document): void
```

### Nullable types (PHP 7.1+)
- ✅ Use `?Type` or `null` in union
```php
public function cancel(?string $reason = null): void
```

## Documentation

### PHPDoc blocks
- ✅ On public methods and properties
- ✅ Describe parameters, return types, exceptions
- ❌ Redundant doc if types are clear

### Comments
- ✅ Explain "why", not "what"
- ✅ Use for complex algorithms, business rules
- ❌ Obvious comments that restate code

## Modularity

### Feature isolation
- ✅ Features live in separate directories or packages
- ✅ Minimal coupling between features
- ✅ Each feature is testable in isolation

### Package independence
- ✅ Shared packages in `packages/`
- ✅ Clear interfaces between packages
- ✅ No circular dependencies

## API Design (if applicable)

### RESTful compliance
- ✅ Resources as nouns (not verbs) — `/orders`, `/users`
- ✅ HTTP methods: GET, POST, PUT/PATCH, DELETE
- ✅ Status codes: 200, 201, 400, 401, 403, 404, 422, 500
- ✅ API versioning: `/api/v1/orders` or header-based

### Consistency
- ✅ Consistent endpoint structure across resources
- ✅ Consistent error response format
- ✅ Consistent pagination format

### Documentation
- ✅ OpenAPI/Swagger specification
- ✅ Endpoint documentation in code or separate docs
