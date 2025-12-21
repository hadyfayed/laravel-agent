#!/bin/bash

# Laravel Agent: Scout Indexing Hook
# Automatically re-indexes models when Searchable models are modified

set -e

FILE_PATH="${1:-}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}Laravel Agent: Scout Indexing Check${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Skip if not a PHP file
if [[ ! "$FILE_PATH" =~ \.php$ ]]; then
    exit 0
fi

# Skip if not a model file
if [[ ! "$FILE_PATH" =~ app/Models/ ]] && [[ ! "$FILE_PATH" =~ Models.*\.php$ ]]; then
    exit 0
fi

# Check if Scout is installed
if ! composer show laravel/scout &>/dev/null; then
    echo -e "${YELLOW}[!] Laravel Scout not installed, skipping${NC}"
    exit 0
fi

# Check if file uses Searchable trait
if ! grep -q "use.*Searchable" "$FILE_PATH" 2>/dev/null; then
    exit 0
fi

# Extract model name from file
MODEL_NAME=$(basename "$FILE_PATH" .php)
MODEL_CLASS="App\\Models\\$MODEL_NAME"

echo -e "\n${GREEN}[✓] Searchable model detected: $MODEL_NAME${NC}"

# Check for toSearchableArray method
if grep -q "toSearchableArray" "$FILE_PATH"; then
    echo -e "${GREEN}[✓] Custom toSearchableArray() found${NC}"
else
    echo -e "${YELLOW}[!] Using default toSearchableArray() - consider customizing for performance${NC}"
fi

# Check for shouldBeSearchable method
if grep -q "shouldBeSearchable" "$FILE_PATH"; then
    echo -e "${GREEN}[✓] Custom shouldBeSearchable() found${NC}"
else
    echo -e "${YELLOW}[!] No shouldBeSearchable() - all records will be indexed${NC}"
fi

# Check for searchableAs method
if grep -q "searchableAs" "$FILE_PATH"; then
    echo -e "${GREEN}[✓] Custom index name defined${NC}"
else
    echo -e "${YELLOW}[i] Using default index name${NC}"
fi

# Suggest re-indexing command
echo -e "\n${BLUE}────────────────────────────────────────${NC}"
echo -e "${BLUE}Suggested Actions:${NC}"
echo -e "${BLUE}────────────────────────────────────────${NC}"
echo -e "1. Sync index settings:"
echo -e "   ${GREEN}php artisan scout:sync-index-settings${NC}"
echo -e ""
echo -e "2. Re-import records (if schema changed):"
echo -e "   ${GREEN}php artisan scout:import \"$MODEL_CLASS\"${NC}"
echo -e ""
echo -e "3. Flush and re-import (if major changes):"
echo -e "   ${GREEN}php artisan scout:flush \"$MODEL_CLASS\"${NC}"
echo -e "   ${GREEN}php artisan scout:import \"$MODEL_CLASS\"${NC}"

# Check for common issues
ISSUES=0

# Check for eager loading in toSearchableArray
if grep -q "toSearchableArray" "$FILE_PATH" && grep -q "\$this->" "$FILE_PATH"; then
    if ! grep -qE "(with\(|load\()" "$FILE_PATH"; then
        echo -e "\n${YELLOW}[!] Potential N+1: Accessing relations in toSearchableArray without eager loading${NC}"
        ISSUES=$((ISSUES + 1))
    fi
fi

# Check for heavy operations in shouldBeSearchable
if grep -qE "shouldBeSearchable.*\{" "$FILE_PATH"; then
    if grep -qA 10 "shouldBeSearchable" "$FILE_PATH" | grep -qE "(DB::|query\(|->get\(|->count\()"; then
        echo -e "\n${YELLOW}[!] Heavy operation in shouldBeSearchable() - this runs on every save${NC}"
        ISSUES=$((ISSUES + 1))
    fi
fi

# Check for large text fields
if grep -q "toSearchableArray" "$FILE_PATH"; then
    if grep -qE "(->description|->content|->body|->text)" "$FILE_PATH"; then
        echo -e "\n${YELLOW}[i] Large text fields detected - consider truncating for index size${NC}"
    fi
fi

echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

if [ $ISSUES -gt 0 ]; then
    echo -e "${YELLOW}Scout check completed with $ISSUES warning(s)${NC}"
    exit 1
else
    echo -e "${GREEN}Scout check passed${NC}"
    exit 0
fi
