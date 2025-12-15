#!/bin/bash
# Laravel Agent Pre-Commit Hook
# Runs before git commit to ensure code quality

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Laravel Agent: Running pre-commit checks...${NC}"

# Get staged PHP files
STAGED_FILES=$(git diff --cached --name-only --diff-filter=ACMR | grep -E '\.php$' || true)

if [ -z "$STAGED_FILES" ]; then
    echo -e "${GREEN}No PHP files staged. Skipping checks.${NC}"
    exit 0
fi

echo "Checking files:"
echo "$STAGED_FILES"
echo ""

# Track if we have errors
HAS_ERRORS=0

# 1. PHP Syntax Check
echo -e "${YELLOW}[1/3] Checking PHP syntax...${NC}"
for FILE in $STAGED_FILES; do
    if [ -f "$FILE" ]; then
        php -l "$FILE" > /dev/null 2>&1 || {
            echo -e "${RED}Syntax error in: $FILE${NC}"
            php -l "$FILE"
            HAS_ERRORS=1
        }
    fi
done

if [ $HAS_ERRORS -eq 0 ]; then
    echo -e "${GREEN}Syntax check passed.${NC}"
fi

# 2. Laravel Pint (Code Style)
echo -e "${YELLOW}[2/3] Running Laravel Pint...${NC}"
if [ -f "vendor/bin/pint" ]; then
    # Run pint on staged files and re-stage if changed
    for FILE in $STAGED_FILES; do
        if [ -f "$FILE" ]; then
            ./vendor/bin/pint "$FILE" --quiet 2>/dev/null || true
            git add "$FILE" 2>/dev/null || true
        fi
    done
    echo -e "${GREEN}Pint formatting applied.${NC}"
elif [ -f "vendor/bin/php-cs-fixer" ]; then
    for FILE in $STAGED_FILES; do
        if [ -f "$FILE" ]; then
            ./vendor/bin/php-cs-fixer fix "$FILE" --quiet 2>/dev/null || true
            git add "$FILE" 2>/dev/null || true
        fi
    done
    echo -e "${GREEN}PHP-CS-Fixer formatting applied.${NC}"
else
    echo -e "${YELLOW}Pint/PHP-CS-Fixer not installed. Skipping code style.${NC}"
fi

# 3. PHPStan (Static Analysis)
echo -e "${YELLOW}[3/3] Running PHPStan...${NC}"
if [ -f "vendor/bin/phpstan" ]; then
    # Run phpstan on staged files
    PHPSTAN_OUTPUT=$(./vendor/bin/phpstan analyse $STAGED_FILES --no-progress --error-format=table 2>&1) || {
        echo -e "${RED}PHPStan found errors:${NC}"
        echo "$PHPSTAN_OUTPUT"
        HAS_ERRORS=1
    }
    if [ $HAS_ERRORS -eq 0 ]; then
        echo -e "${GREEN}PHPStan analysis passed.${NC}"
    fi
else
    echo -e "${YELLOW}PHPStan not installed. Skipping static analysis.${NC}"
fi

# Final result
echo ""
if [ $HAS_ERRORS -ne 0 ]; then
    echo -e "${RED}Pre-commit checks failed. Please fix errors before committing.${NC}"
    exit 2  # Exit code 2 = blocking error in Claude Code hooks
fi

echo -e "${GREEN}All pre-commit checks passed!${NC}"
exit 0
