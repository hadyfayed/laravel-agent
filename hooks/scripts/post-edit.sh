#!/bin/bash
# Laravel Agent Post-Edit Hook
# Runs after file edits to maintain code quality

FILE_PATH="$1"

# Exit if no file path provided
if [ -z "$FILE_PATH" ]; then
    exit 0
fi

# Only process PHP files
if [[ ! "$FILE_PATH" =~ \.php$ ]]; then
    exit 0
fi

# Exit if file doesn't exist (was deleted)
if [ ! -f "$FILE_PATH" ]; then
    exit 0
fi

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 1. Auto-format with Laravel Pint
if [ -f "vendor/bin/pint" ]; then
    ./vendor/bin/pint "$FILE_PATH" --quiet 2>/dev/null
    echo -e "${GREEN}Formatted: $FILE_PATH${NC}"
elif [ -f "vendor/bin/php-cs-fixer" ]; then
    ./vendor/bin/php-cs-fixer fix "$FILE_PATH" --quiet 2>/dev/null
    echo -e "${GREEN}Formatted: $FILE_PATH${NC}"
fi

# 2. Update IDE Helper if model was modified
if [[ "$FILE_PATH" =~ app/Models/ ]] || [[ "$FILE_PATH" =~ Models/ ]]; then
    if [ -f "vendor/bin/ide-helper" ] || php artisan list 2>/dev/null | grep -q "ide-helper:models"; then
        # Get model name from file path
        MODEL_NAME=$(basename "$FILE_PATH" .php)

        # Generate model helper for this specific model
        php artisan ide-helper:models "App\\Models\\$MODEL_NAME" --write --quiet 2>/dev/null || true
        echo -e "${GREEN}Updated IDE helper for: $MODEL_NAME${NC}"
    fi
fi

exit 0
