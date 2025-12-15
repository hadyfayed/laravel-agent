#!/bin/bash
# Laravel Agent Pre-Commit Hook
# Runs before git commit to ensure code quality
# Supports parallel execution for better performance

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PARALLEL_JOBS=${PARALLEL_JOBS:-4}
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}Laravel Agent: Pre-Commit Checks${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Get staged files
STAGED_PHP=$(git diff --cached --name-only --diff-filter=ACMR | grep -E '\.php$' || true)
STAGED_BLADE=$(git diff --cached --name-only --diff-filter=ACMR | grep -E '\.blade\.php$' || true)
STAGED_ENV=$(git diff --cached --name-only --diff-filter=ACMR | grep -E '\.env' || true)
STAGED_MIGRATIONS=$(git diff --cached --name-only --diff-filter=ACMR | grep -E 'database/migrations/.*\.php$' || true)

if [ -z "$STAGED_PHP" ] && [ -z "$STAGED_BLADE" ] && [ -z "$STAGED_ENV" ]; then
    echo -e "${GREEN}No relevant files staged. Skipping checks.${NC}"
    exit 0
fi

echo "Staged files:"
[ -n "$STAGED_PHP" ] && echo "  PHP: $(echo "$STAGED_PHP" | wc -l | tr -d ' ') files"
[ -n "$STAGED_BLADE" ] && echo "  Blade: $(echo "$STAGED_BLADE" | wc -l | tr -d ' ') files"
[ -n "$STAGED_ENV" ] && echo "  Env: $(echo "$STAGED_ENV" | wc -l | tr -d ' ') files"
[ -n "$STAGED_MIGRATIONS" ] && echo "  Migrations: $(echo "$STAGED_MIGRATIONS" | wc -l | tr -d ' ') files"
echo ""

# Track overall status
OVERALL_STATUS=0

# Function to run check and store result
run_check() {
    local NAME="$1"
    local COMMAND="$2"
    local OUTPUT_FILE="$TEMP_DIR/$NAME"

    echo -e "${YELLOW}[Running] $NAME...${NC}"

    if eval "$COMMAND" > "$OUTPUT_FILE" 2>&1; then
        echo -e "${GREEN}[✓] $NAME passed${NC}"
        return 0
    else
        echo -e "${RED}[✗] $NAME failed${NC}"
        cat "$OUTPUT_FILE"
        return 1
    fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# PHP CHECKS
# ═══════════════════════════════════════════════════════════════════════════════

if [ -n "$STAGED_PHP" ]; then
    echo -e "\n${BLUE}PHP Checks${NC}"
    echo "────────────────────────────────────────"

    # 1. PHP Syntax Check (parallel)
    SYNTAX_ERRORS=0
    echo -e "${YELLOW}[1/4] PHP Syntax Check...${NC}"
    for FILE in $STAGED_PHP; do
        if [ -f "$FILE" ]; then
            if ! php -l "$FILE" > /dev/null 2>&1; then
                echo -e "${RED}Syntax error in: $FILE${NC}"
                php -l "$FILE"
                SYNTAX_ERRORS=1
            fi
        fi
    done
    if [ $SYNTAX_ERRORS -eq 0 ]; then
        echo -e "${GREEN}[✓] Syntax check passed${NC}"
    else
        OVERALL_STATUS=1
    fi

    # 2. Laravel Pint (Code Style)
    echo -e "${YELLOW}[2/4] Laravel Pint...${NC}"
    if [ -f "vendor/bin/pint" ]; then
        for FILE in $STAGED_PHP; do
            if [ -f "$FILE" ]; then
                ./vendor/bin/pint "$FILE" --quiet 2>/dev/null || true
                git add "$FILE" 2>/dev/null || true
            fi
        done
        echo -e "${GREEN}[✓] Pint formatting applied${NC}"
    elif [ -f "vendor/bin/php-cs-fixer" ]; then
        for FILE in $STAGED_PHP; do
            if [ -f "$FILE" ]; then
                ./vendor/bin/php-cs-fixer fix "$FILE" --quiet 2>/dev/null || true
                git add "$FILE" 2>/dev/null || true
            fi
        done
        echo -e "${GREEN}[✓] PHP-CS-Fixer formatting applied${NC}"
    else
        echo -e "${YELLOW}[⊘] Pint/PHP-CS-Fixer not installed. Skipping.${NC}"
    fi

    # 3. PHPStan (Static Analysis)
    echo -e "${YELLOW}[3/4] PHPStan...${NC}"
    if [ -f "vendor/bin/phpstan" ]; then
        if ./vendor/bin/phpstan analyse $STAGED_PHP --no-progress --error-format=table 2>&1; then
            echo -e "${GREEN}[✓] PHPStan passed${NC}"
        else
            echo -e "${RED}[✗] PHPStan found errors${NC}"
            OVERALL_STATUS=1
        fi
    else
        echo -e "${YELLOW}[⊘] PHPStan not installed. Skipping.${NC}"
    fi

    # 4. Security Scan
    echo -e "${YELLOW}[4/4] Security Scan...${NC}"
    SECURITY_ISSUES=0
    for FILE in $STAGED_PHP; do
        if [ -f "$FILE" ]; then
            # Check for debug functions
            if grep -qE '\b(dd|dump|var_dump|print_r)\s*\(' "$FILE" 2>/dev/null; then
                echo -e "${YELLOW}  Debug function in: $FILE${NC}"
            fi
            # Check for potential secrets
            if grep -qiE 'password["\047]?\s*[=:]\s*["\047][^"\047]{8,}' "$FILE" 2>/dev/null; then
                echo -e "${RED}  Potential hardcoded password in: $FILE${NC}"
                SECURITY_ISSUES=1
            fi
        fi
    done
    if [ $SECURITY_ISSUES -eq 0 ]; then
        echo -e "${GREEN}[✓] Security scan passed${NC}"
    else
        OVERALL_STATUS=1
    fi
fi

# ═══════════════════════════════════════════════════════════════════════════════
# BLADE CHECKS
# ═══════════════════════════════════════════════════════════════════════════════

if [ -n "$STAGED_BLADE" ]; then
    echo -e "\n${BLUE}Blade Checks${NC}"
    echo "────────────────────────────────────────"

    BLADE_ERRORS=0
    for FILE in $STAGED_BLADE; do
        if [ -f "$FILE" ]; then
            # Check for CSRF in forms
            if grep -qE '<form[^>]*method\s*=\s*["\047](post|put|patch|delete)["\047]' "$FILE" 2>/dev/null; then
                FORM_CONTENT=$(cat "$FILE")
                if ! echo "$FORM_CONTENT" | grep -qE '@csrf|csrf_field'; then
                    echo -e "${RED}Missing @csrf in form: $FILE${NC}"
                    BLADE_ERRORS=1
                fi
            fi

            # Check for unescaped output
            UNESCAPED=$(grep -c '{!!' "$FILE" 2>/dev/null || echo 0)
            if [ "$UNESCAPED" -gt 0 ]; then
                echo -e "${YELLOW}Unescaped output ({!!...!!}) in: $FILE ($UNESCAPED occurrences)${NC}"
            fi
        fi
    done

    if [ $BLADE_ERRORS -eq 0 ]; then
        echo -e "${GREEN}[✓] Blade checks passed${NC}"
    else
        OVERALL_STATUS=1
    fi
fi

# ═══════════════════════════════════════════════════════════════════════════════
# MIGRATION CHECKS
# ═══════════════════════════════════════════════════════════════════════════════

if [ -n "$STAGED_MIGRATIONS" ]; then
    echo -e "\n${BLUE}Migration Safety Checks${NC}"
    echo "────────────────────────────────────────"

    for FILE in $STAGED_MIGRATIONS; do
        if [ -f "$FILE" ]; then
            # Check for dangerous operations
            if grep -qE 'dropColumn|dropTable|drop|truncate' "$FILE" 2>/dev/null; then
                echo -e "${YELLOW}WARNING: Destructive operation in: $FILE${NC}"
                grep -nE 'dropColumn|dropTable|drop|truncate' "$FILE" 2>/dev/null | head -3
            fi

            # Check for missing down()
            if ! grep -q "public function down" "$FILE" 2>/dev/null; then
                echo -e "${YELLOW}WARNING: No down() method in: $FILE${NC}"
            fi
        fi
    done
    echo -e "${GREEN}[✓] Migration safety check complete${NC}"
fi

# ═══════════════════════════════════════════════════════════════════════════════
# ENV CHECKS
# ═══════════════════════════════════════════════════════════════════════════════

if [ -n "$STAGED_ENV" ]; then
    echo -e "\n${BLUE}Environment Checks${NC}"
    echo "────────────────────────────────────────"

    for FILE in $STAGED_ENV; do
        if [[ "$FILE" =~ \.env$ ]] && [[ ! "$FILE" =~ \.env\.example$ ]]; then
            echo -e "${RED}ERROR: .env file should not be committed: $FILE${NC}"
            OVERALL_STATUS=1
        fi
    done

    if [ $OVERALL_STATUS -eq 0 ]; then
        echo -e "${GREEN}[✓] Environment checks passed${NC}"
    fi
fi

# ═══════════════════════════════════════════════════════════════════════════════
# FINAL RESULT
# ═══════════════════════════════════════════════════════════════════════════════

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

if [ $OVERALL_STATUS -ne 0 ]; then
    echo -e "${RED}Pre-commit checks FAILED. Please fix errors before committing.${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    exit 2  # Blocking error for Claude Code hooks
fi

echo -e "${GREEN}All pre-commit checks PASSED!${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
exit 0
