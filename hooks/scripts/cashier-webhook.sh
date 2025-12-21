#!/bin/bash

# Laravel Agent: Cashier Webhook Validation Hook
# Validates Cashier webhook handlers and Stripe integration

set -e

FILE_PATH="${1:-}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Skip if not a PHP file
if [[ ! "$FILE_PATH" =~ \.php$ ]]; then
    exit 0
fi

# Check if this is a webhook-related file
IS_WEBHOOK=false
IS_CASHIER=false

if grep -qE "(WebhookController|handleWebhook|stripe.*webhook)" "$FILE_PATH" 2>/dev/null; then
    IS_WEBHOOK=true
fi

if grep -qE "(use.*Cashier|Billable|Subscription|checkout|newSubscription)" "$FILE_PATH" 2>/dev/null; then
    IS_CASHIER=true
fi

# Skip if not relevant
if [[ "$IS_WEBHOOK" == "false" && "$IS_CASHIER" == "false" ]]; then
    exit 0
fi

echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}Laravel Agent: Cashier/Stripe Validation${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

ISSUES=0
WARNINGS=0

# Check for Cashier installation
if ! composer show laravel/cashier &>/dev/null 2>&1; then
    echo -e "${YELLOW}[!] Laravel Cashier not installed${NC}"
    exit 0
fi

echo -e "\n${GREEN}[✓] Laravel Cashier detected${NC}"

# === WEBHOOK CHECKS ===
if [[ "$IS_WEBHOOK" == "true" ]]; then
    echo -e "\n${BLUE}Webhook Handler Checks${NC}"
    echo -e "${BLUE}────────────────────────────────────────${NC}"

    # Check for webhook signature verification
    if grep -qE "extends.*WebhookController" "$FILE_PATH"; then
        echo -e "${GREEN}[✓] Extends CashierWebhookController (signature verified)${NC}"
    else
        if ! grep -qE "(Stripe\\\\Webhook::constructEvent|verifyWebhookSignature)" "$FILE_PATH"; then
            echo -e "${RED}[✗] No webhook signature verification found!${NC}"
            echo -e "    Stripe webhooks must verify signatures to prevent spoofing"
            ISSUES=$((ISSUES + 1))
        fi
    fi

    # Check for CSRF exception
    ROUTES_FILE="routes/web.php"
    if [[ -f "$ROUTES_FILE" ]]; then
        if grep -qE "stripe.*webhook" "$ROUTES_FILE"; then
            if ! grep -q "withoutMiddleware.*VerifyCsrfToken" "$ROUTES_FILE"; then
                echo -e "${YELLOW}[!] Webhook route may need CSRF exception${NC}"
                echo -e "    Add: ->withoutMiddleware(VerifyCsrfToken::class)"
                WARNINGS=$((WARNINGS + 1))
            fi
        fi
    fi

    # Check for proper event handling
    WEBHOOK_EVENTS=(
        "handleCustomerSubscriptionCreated"
        "handleCustomerSubscriptionUpdated"
        "handleCustomerSubscriptionDeleted"
        "handleInvoicePaymentSucceeded"
        "handleInvoicePaymentFailed"
    )

    echo -e "\n${BLUE}Webhook Event Handlers:${NC}"
    for event in "${WEBHOOK_EVENTS[@]}"; do
        if grep -q "$event" "$FILE_PATH"; then
            echo -e "  ${GREEN}[✓] $event${NC}"
        else
            echo -e "  ${YELLOW}[-] $event (using default)${NC}"
        fi
    done

    # Check for proper exception handling
    if ! grep -qE "(try.*catch|handleWebhook.*Exception)" "$FILE_PATH"; then
        echo -e "\n${YELLOW}[!] Consider adding exception handling for webhook failures${NC}"
        WARNINGS=$((WARNINGS + 1))
    fi

    # Check for idempotency
    if ! grep -qE "(idempotency|processed_webhooks|webhook.*id)" "$FILE_PATH"; then
        echo -e "${YELLOW}[!] Consider implementing idempotency for webhook retries${NC}"
        WARNINGS=$((WARNINGS + 1))
    fi
fi

# === CASHIER/BILLABLE CHECKS ===
if [[ "$IS_CASHIER" == "true" ]]; then
    echo -e "\n${BLUE}Cashier Integration Checks${NC}"
    echo -e "${BLUE}────────────────────────────────────────${NC}"

    # Check for Billable trait on User model
    if [[ "$FILE_PATH" =~ Models/User\.php ]]; then
        if grep -q "use Billable" "$FILE_PATH"; then
            echo -e "${GREEN}[✓] Billable trait used${NC}"
        else
            echo -e "${RED}[✗] User model missing Billable trait${NC}"
            ISSUES=$((ISSUES + 1))
        fi
    fi

    # Check for hardcoded prices
    if grep -qE "(price_[a-zA-Z0-9]{10,}|prod_[a-zA-Z0-9]{10,})" "$FILE_PATH"; then
        echo -e "${YELLOW}[!] Hardcoded Stripe IDs found - consider using config${NC}"
        echo -e "    Move to config/cashier.php or .env"
        WARNINGS=$((WARNINGS + 1))
    fi

    # Check for test mode indicators in production code
    if grep -qE "pk_test_|sk_test_" "$FILE_PATH"; then
        echo -e "${RED}[✗] Test API keys found in code!${NC}"
        echo -e "    Move to .env: STRIPE_KEY, STRIPE_SECRET"
        ISSUES=$((ISSUES + 1))
    fi

    # Check for proper subscription handling
    if grep -q "newSubscription" "$FILE_PATH"; then
        echo -e "${GREEN}[✓] Subscription creation found${NC}"

        # Check for trial handling
        if grep -qE "(trialDays|trialUntil)" "$FILE_PATH"; then
            echo -e "  ${GREEN}[✓] Trial period configured${NC}"
        fi

        # Check for error handling
        if grep -qE "(try.*catch|IncompletePayment|PaymentFailure)" "$FILE_PATH"; then
            echo -e "  ${GREEN}[✓] Payment error handling present${NC}"
        else
            echo -e "  ${YELLOW}[!] Consider handling IncompletePayment exceptions${NC}"
            WARNINGS=$((WARNINGS + 1))
        fi
    fi

    # Check for checkout usage
    if grep -q "->checkout(" "$FILE_PATH"; then
        echo -e "${GREEN}[✓] Stripe Checkout integration found${NC}"

        if ! grep -qE "(success_url|cancel_url)" "$FILE_PATH"; then
            echo -e "  ${YELLOW}[!] Ensure success_url and cancel_url are set${NC}"
            WARNINGS=$((WARNINGS + 1))
        fi
    fi
fi

# === ENVIRONMENT CHECKS ===
echo -e "\n${BLUE}Environment Configuration${NC}"
echo -e "${BLUE}────────────────────────────────────────${NC}"

# Check .env.example for Stripe keys
if [[ -f ".env.example" ]]; then
    if grep -q "STRIPE_KEY" ".env.example"; then
        echo -e "${GREEN}[✓] STRIPE_KEY in .env.example${NC}"
    else
        echo -e "${YELLOW}[!] Add STRIPE_KEY to .env.example${NC}"
        WARNINGS=$((WARNINGS + 1))
    fi

    if grep -q "STRIPE_SECRET" ".env.example"; then
        echo -e "${GREEN}[✓] STRIPE_SECRET in .env.example${NC}"
    else
        echo -e "${YELLOW}[!] Add STRIPE_SECRET to .env.example${NC}"
        WARNINGS=$((WARNINGS + 1))
    fi

    if grep -q "STRIPE_WEBHOOK_SECRET" ".env.example"; then
        echo -e "${GREEN}[✓] STRIPE_WEBHOOK_SECRET in .env.example${NC}"
    else
        echo -e "${YELLOW}[!] Add STRIPE_WEBHOOK_SECRET to .env.example${NC}"
        WARNINGS=$((WARNINGS + 1))
    fi
fi

# === SUMMARY ===
echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

if [ $ISSUES -gt 0 ]; then
    echo -e "${RED}Cashier check failed with $ISSUES error(s) and $WARNINGS warning(s)${NC}"
    exit 2
elif [ $WARNINGS -gt 0 ]; then
    echo -e "${YELLOW}Cashier check passed with $WARNINGS warning(s)${NC}"
    exit 1
else
    echo -e "${GREEN}Cashier check passed${NC}"
    exit 0
fi
