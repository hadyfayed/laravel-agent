#!/bin/bash
# Laravel Agent Environment Check Hook
# Validates .env files and checks for security issues

set -e

FILE_PATH="$1"

# Colors
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

# Exit if no file path
if [ -z "$FILE_PATH" ]; then
    exit 0
fi

# Only check .env files
if [[ ! "$FILE_PATH" =~ \.env ]]; then
    exit 0
fi

# Exit if file doesn't exist
if [ ! -f "$FILE_PATH" ]; then
    exit 0
fi

echo -e "${YELLOW}Environment check: $FILE_PATH${NC}"

HAS_WARNINGS=0
HAS_ERRORS=0

# Block committing actual .env files (not .env.example)
if [[ "$FILE_PATH" =~ \.env$ ]] && [[ ! "$FILE_PATH" =~ \.env\.example$ ]]; then
    echo -e "${RED}ERROR: .env files should not be committed!${NC}"
    echo "Add to .gitignore: .env"
    exit 2
fi

# For .env.example, check for placeholder values
if [[ "$FILE_PATH" =~ \.env\.example$ ]]; then

    # Check for real values that should be placeholders
    if grep -qE '^(APP_KEY|DB_PASSWORD|MAIL_PASSWORD|AWS_SECRET|STRIPE_SECRET)=[^$]' "$FILE_PATH" 2>/dev/null; then
        REAL_VALUES=$(grep -E '^(APP_KEY|DB_PASSWORD|MAIL_PASSWORD|AWS_SECRET|STRIPE_SECRET)=[^$]' "$FILE_PATH" 2>/dev/null | grep -v '=$\|=null$\|=your-\|=xxx' || true)
        if [ -n "$REAL_VALUES" ]; then
            echo -e "${RED}ERROR: Real secrets found in .env.example:${NC}"
            echo "$REAL_VALUES"
            HAS_ERRORS=1
        fi
    fi

    # Check for required Laravel variables
    REQUIRED_VARS=(
        "APP_NAME"
        "APP_ENV"
        "APP_KEY"
        "APP_DEBUG"
        "APP_URL"
        "DB_CONNECTION"
        "DB_HOST"
        "DB_PORT"
        "DB_DATABASE"
        "DB_USERNAME"
        "DB_PASSWORD"
    )

    for VAR in "${REQUIRED_VARS[@]}"; do
        if ! grep -q "^${VAR}=" "$FILE_PATH" 2>/dev/null; then
            echo -e "${YELLOW}WARNING: Missing required variable: $VAR${NC}"
            HAS_WARNINGS=1
        fi
    done

    # Check for APP_DEBUG=true (should be false in example)
    if grep -qE '^APP_DEBUG=true' "$FILE_PATH" 2>/dev/null; then
        echo -e "${YELLOW}WARNING: APP_DEBUG=true in .env.example (should be false for safety)${NC}"
        HAS_WARNINGS=1
    fi

    # Check for insecure session/cache settings
    if grep -qE '^SESSION_DRIVER=file' "$FILE_PATH" 2>/dev/null; then
        echo -e "${YELLOW}INFO: Consider using redis/database for SESSION_DRIVER in production${NC}"
    fi

    if grep -qE '^CACHE_DRIVER=file' "$FILE_PATH" 2>/dev/null; then
        echo -e "${YELLOW}INFO: Consider using redis for CACHE_DRIVER in production${NC}"
    fi

    # Check for localhost URLs
    if grep -qE '^APP_URL=http://localhost' "$FILE_PATH" 2>/dev/null; then
        # This is fine for .env.example
        :
    fi

    # Validate syntax (no spaces around =)
    if grep -qE '^[A-Z_]+\s+=\s*' "$FILE_PATH" 2>/dev/null; then
        echo -e "${YELLOW}WARNING: Invalid syntax - spaces around = found:${NC}"
        grep -nE '^[A-Z_]+\s+=\s*' "$FILE_PATH" 2>/dev/null | head -3
        HAS_WARNINGS=1
    fi

    # Check for duplicate keys
    DUPLICATES=$(grep -E '^[A-Z_]+=' "$FILE_PATH" 2>/dev/null | cut -d= -f1 | sort | uniq -d)
    if [ -n "$DUPLICATES" ]; then
        echo -e "${YELLOW}WARNING: Duplicate environment variables:${NC}"
        echo "$DUPLICATES"
        HAS_WARNINGS=1
    fi

    # Check for comments that might contain secrets
    if grep -qE '^#.*password|^#.*secret|^#.*key.*=' "$FILE_PATH" 2>/dev/null; then
        echo -e "${YELLOW}WARNING: Comments might contain sensitive information${NC}"
        grep -nE '^#.*password|^#.*secret|^#.*key.*=' "$FILE_PATH" 2>/dev/null | head -3
        HAS_WARNINGS=1
    fi
fi

# Summary
if [ $HAS_ERRORS -ne 0 ]; then
    echo -e "${RED}Environment check failed.${NC}"
    exit 2
fi

if [ $HAS_WARNINGS -ne 0 ]; then
    echo -e "${YELLOW}Environment check passed with warnings.${NC}"
    exit 0
fi

echo -e "${GREEN}Environment check passed.${NC}"
exit 0
