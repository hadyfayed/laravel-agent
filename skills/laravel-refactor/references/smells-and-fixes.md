# Code Smell Detection & Fixes

## SOLID Violations

| Principle | Smell | Fix | Example |
|-----------|-------|-----|---------|
| SRP | Class does multiple things | Extract to services/actions | OrderController doing auth + validation + business logic |
| SRP | Method > 20 lines | Extract methods | store() method with 50 lines |
| OCP | Switch on type | Strategy pattern | if/elseif on payment types |
| LSP | Type checking in subclass | Proper contracts | Model subclass with extra validation |
| ISP | Unused interface methods | Segregate interfaces | PaymentInterface with all payment types' methods |
| DIP | Direct instantiation | Constructor injection | new PaymentService() instead of injected |

## DRY Violations

| Smell | Fix | Example |
|-------|-----|---------|
| Same code 2+ places | Extract to method/class | Login validation repeated in 3 controllers |
| Similar queries | Query scope | ->whereStatus('active') repeated everywhere |
| Repeated validation | Trait/base rules | Same email validation in 5 models |

## Code Smell Thresholds

| Smell | Threshold | Fix |
|-------|-----------|-----|
| God class | >300 lines | Split by responsibility |
| Long method | >20 lines | Extract methods |
| Long params | >4 params | Use DTO/value object |
| Deep nesting | >3 levels | Early return, extract method |
| Cyclomatic complexity | >5 | Simplify branches |

## Detection Queries

### Find god classes
```bash
find app -name "*.php" -exec wc -l {} + | sort -rn | head -20
```

### Find long methods
```bash
grep -r "function " app --include="*.php" | \
  while read -r file; do
    php -r "echo file_get_contents('${file%:*}');" | \
    grep -A 20 "function" | wc -l
  done
```

### Find repeated code patterns
```bash
grep -r "protected \$rules = " app --include="*.php" | head -10
grep -r "whereStatus('active')" app --include="*.php"
```

## Common Refactoring Moves

### Extract Service from Controller

**Before:**
```php
class OrderController {
    public function store(Request $request) {
        $validated = $request->validate([...]);
        $order = Order::create($validated);
        // 30 more lines of business logic
        return redirect()->route('orders.show', $order);
    }
}
```

**After:**
```php
class OrderController {
    public function store(CreateOrderRequest $request, CreateOrderAction $action) {
        $order = $action->execute(OrderData::fromRequest($request));
        return redirect()->route('orders.show', $order);
    }
}
```

### Extract Method

**Before:**
```php
public function processPayment($data) {
    // Validate data
    $amount = $data['amount'];
    if ($amount <= 0) throw new Exception();
    // Check balance
    $user = User::find($data['user_id']);
    if ($user->balance < $amount) throw new Exception();
    // Process transaction
    // 20 more lines
}
```

**After:**
```php
public function processPayment(array $data): Transaction {
    $validated = $this->validatePaymentData($data);
    $this->checkSufficientBalance($validated);
    return $this->executeTransaction($validated);
}

private function validatePaymentData(array $data): PaymentData { ... }
private function checkSufficientBalance(PaymentData $data): void { ... }
private function executeTransaction(PaymentData $data): Transaction { ... }
```

### Replace Conditional with Strategy

**Before:**
```php
$handler = match($payment->type) {
    'stripe' => new StripePaymentHandler(),
    'paypal' => new PayPalPaymentHandler(),
    'square' => new SquarePaymentHandler(),
};
return $handler->handle($payment);
```

**After:**
```php
$handler = $this->paymentHandlerFactory->make($payment->type);
return $handler->handle($payment);
```

## Type Declaration Best Practices

```php
// Before
public function process($data) {
    return $this->service->execute($data);
}

// After
public function process(array $data): OrderData {
    return $this->service->execute(OrderData::from($data));
}
```
