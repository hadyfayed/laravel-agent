# SOLID Extraction Patterns

## Single Responsibility Principle (SRP)

### When to Extract

- Class has more than 2 reasons to change
- Method names contain "and" ("validateAndCreate")
- Methods don't use all class properties
- Test class requires multiple mocks

### Strategy: Extract Service

```php
// Before: Controller does too much
class OrderController {
    public function store(StoreOrderRequest $request) {
        $order = Order::create($request->validated());
        // Inventory management logic
        Stock::decrement($order->items);
        // Email notification
        OrderCreatedMail::dispatch($order);
        // Analytics
        Analytics::track('order.created', $order->id);
        return redirect()->route('orders.show', $order);
    }
}

// After: Extract to action
class CreateOrderAction {
    public function execute(OrderData $data): Order {
        $order = Order::create($data->toArray());
        return $order;
    }
}

class OrderController {
    public function store(
        StoreOrderRequest $request,
        CreateOrderAction $createOrder,
        OrderWorkflow $workflow
    ) {
        $order = $createOrder->execute(OrderData::fromRequest($request));
        $workflow->process($order);
        return redirect()->route('orders.show', $order);
    }
}

class OrderWorkflow {
    public function __construct(
        private StockService $stock,
        private NotificationService $notification,
        private AnalyticsService $analytics,
    ) {}

    public function process(Order $order): void {
        $this->stock->decrement($order->items);
        $this->notification->send(new OrderCreatedMail($order));
        $this->analytics->track('order.created', $order->id);
    }
}
```

### Strategy: Extract Method

```php
// Before: Long method
public function import(array $data) {
    $users = [];
    foreach ($data as $row) {
        if (empty($row['email'])) continue;
        if (User::where('email', $row['email'])->exists()) continue;
        $user = new User([
            'name' => $row['name'],
            'email' => $row['email'],
            'password' => Hash::make($row['password'] ?? str()->random(16)),
        ]);
        if ($user->save()) {
            $users[] = $user;
            Log::info('User imported', ['email' => $row['email']]);
        } else {
            Log::error('Failed to import user', ['email' => $row['email']]);
        }
    }
    return $users;
}

// After: Extracted methods
public function import(array $data): array {
    return array_values(array_filter(
        array_map(fn($row) => $this->importRow($row), $data)
    ));
}

private function importRow(array $row): ?User {
    if (!$this->isValidRow($row)) return null;
    if ($this->userExists($row['email'])) return null;

    $user = $this->createUser($row);
    return $user->save() ? $user : null;
}

private function isValidRow(array $row): bool {
    return !empty($row['email']);
}

private function userExists(string $email): bool {
    return User::where('email', $email)->exists();
}

private function createUser(array $row): User {
    return new User([
        'name' => $row['name'],
        'email' => $row['email'],
        'password' => Hash::make($row['password'] ?? str()->random(16)),
    ]);
}
```

## Open/Closed Principle (OCP)

### When to Extract

- Adding new feature requires modifying existing class
- Switch/if chains on types
- Different behavior per entity

### Strategy: Use Strategy Pattern

```php
// Before: Switch on type
class PaymentProcessor {
    public function process(Payment $payment): Result {
        return match($payment->type) {
            'stripe' => $this->processStripe($payment),
            'paypal' => $this->processPayPal($payment),
            'square' => $this->processSquare($payment),
        };
    }

    // Adding new payment type requires modifying this class
}

// After: Strategy pattern
interface PaymentStrategy {
    public function process(Payment $payment): Result;
}

class StripePaymentStrategy implements PaymentStrategy {
    public function process(Payment $payment): Result { ... }
}

class PayPalPaymentStrategy implements PaymentStrategy {
    public function process(Payment $payment): Result { ... }
}

class PaymentProcessor {
    public function __construct(
        private PaymentStrategyFactory $factory
    ) {}

    public function process(Payment $payment): Result {
        $strategy = $this->factory->make($payment->type);
        return $strategy->process($payment);
    }
}

// New payment type: create new strategy, register in factory
// No modification to PaymentProcessor needed
```

## Dependency Inversion Principle (DIP)

### When to Extract

- Direct instantiation with `new`
- Circular dependencies
- Hard to test (can't mock dependencies)

### Strategy: Constructor Injection

```php
// Before: Direct instantiation
class OrderService {
    public function create(OrderData $data): Order {
        $emailService = new EmailService(); // Tightly coupled
        $analyticsService = new AnalyticsService(); // Hard to test
        
        $order = Order::create($data->toArray());
        $emailService->send($order);
        $analyticsService->track($order);
        return $order;
    }
}

// After: Inject dependencies
class OrderService {
    public function __construct(
        private EmailServiceInterface $emailService,
        private AnalyticsServiceInterface $analyticsService,
    ) {}

    public function create(OrderData $data): Order {
        $order = Order::create($data->toArray());
        $this->emailService->send($order);
        $this->analyticsService->track($order);
        return $order;
    }
}

// In service provider:
$this->app->bind(
    EmailServiceInterface::class,
    EmailService::class
);

// In tests:
$mockEmail = Mockery::mock(EmailServiceInterface::class);
$service = new OrderService($mockEmail, ...);
```
