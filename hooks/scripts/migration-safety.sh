#!/bin/bash
# Laravel Agent Migration Safety Hook
# Checks migrations for potentially dangerous operations

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

# Only check migration files
if [[ ! "$FILE_PATH" =~ database/migrations/.*\.php$ ]]; then
    exit 0
fi

# Exit if file doesn't exist
if [ ! -f "$FILE_PATH" ]; then
    exit 0
fi

echo -e "${YELLOW}Migration safety check: $FILE_PATH${NC}"

HAS_WARNINGS=0
HAS_ERRORS=0

# Dangerous operations that need confirmation
declare -a DANGEROUS_OPS=(
    "dropColumn"
    "dropTable"
    "drop"
    "dropIfExists"
    "dropForeign"
    "dropIndex"
    "dropUnique"
    "dropPrimary"
    "renameColumn"
    "rename"
    "truncate"
)

# Check for dangerous operations
for op in "${DANGEROUS_OPS[@]}"; do
    if grep -q "$op" "$FILE_PATH" 2>/dev/null; then
        echo -e "${YELLOW}WARNING: Found '$op' - this may cause data loss:${NC}"
        grep -n "$op" "$FILE_PATH" 2>/dev/null | head -3
        HAS_WARNINGS=1
    fi
done

# Check for raw SQL (potential injection if not careful)
if grep -qE 'DB::statement|DB::unprepared|DB::raw' "$FILE_PATH" 2>/dev/null; then
    echo -e "${YELLOW}WARNING: Raw SQL found - ensure it's safe:${NC}"
    grep -nE 'DB::statement|DB::unprepared|DB::raw' "$FILE_PATH" 2>/dev/null | head -3
    HAS_WARNINGS=1
fi

# Check for missing down() method
if ! grep -q "public function down" "$FILE_PATH" 2>/dev/null; then
    echo -e "${YELLOW}WARNING: No down() method - rollback not possible${NC}"
    HAS_WARNINGS=1
fi

# Check for non-nullable columns without defaults (could fail on existing data)
if grep -qE '->nullable\(\s*false\s*\)' "$FILE_PATH" 2>/dev/null; then
    echo -e "${YELLOW}WARNING: Non-nullable column - may fail if table has existing data${NC}"
    grep -nE '->nullable\(\s*false\s*\)' "$FILE_PATH" 2>/dev/null | head -3
    HAS_WARNINGS=1
fi

# Check for adding columns without default on existing tables
if grep -qE 'Schema::table.*function.*\$table' "$FILE_PATH" 2>/dev/null; then
    # Check if there's a column addition without nullable or default
    if grep -qE '\$table->(string|integer|text|boolean|date|timestamp|decimal|float|json|uuid)' "$FILE_PATH" 2>/dev/null; then
        if ! grep -qE '->nullable\(\)|->default\(' "$FILE_PATH" 2>/dev/null; then
            echo -e "${YELLOW}WARNING: Adding column to existing table - consider nullable() or default()${NC}"
            HAS_WARNINGS=1
        fi
    fi
fi

# Check for production environment
if [ "$APP_ENV" = "production" ] && [ $HAS_WARNINGS -ne 0 ]; then
    echo -e "${RED}BLOCKED: Dangerous migration operations detected in production${NC}"
    HAS_ERRORS=1
fi

# Summary
if [ $HAS_ERRORS -ne 0 ]; then
    echo -e "${RED}Migration blocked due to dangerous operations in production.${NC}"
    exit 2
fi

if [ $HAS_WARNINGS -ne 0 ]; then
    echo -e "${YELLOW}Migration has warnings. Review carefully before running.${NC}"
    exit 0  # Allow but warn
fi

echo -e "${GREEN}Migration safety check passed.${NC}"
exit 0
