#!/bin/bash
# Laravel Agent Blade Linting Hook
# Checks Blade templates for common issues

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

# Only check Blade files
if [[ ! "$FILE_PATH" =~ \.blade\.php$ ]]; then
    exit 0
fi

# Exit if file doesn't exist
if [ ! -f "$FILE_PATH" ]; then
    exit 0
fi

echo -e "${YELLOW}Blade lint: $FILE_PATH${NC}"

HAS_WARNINGS=0
HAS_ERRORS=0

# Check for unescaped output (potential XSS)
if grep -qE '\{!!\s*\$' "$FILE_PATH" 2>/dev/null; then
    echo -e "${YELLOW}WARNING: Unescaped output found - potential XSS risk:${NC}"
    grep -nE '\{!!\s*\$' "$FILE_PATH" 2>/dev/null | head -5
    HAS_WARNINGS=1
fi

# Check for inline PHP (should use Blade directives)
if grep -qE '<\?php|<\?=' "$FILE_PATH" 2>/dev/null; then
    echo -e "${YELLOW}WARNING: Inline PHP found - use Blade directives instead:${NC}"
    grep -nE '<\?php|<\?=' "$FILE_PATH" 2>/dev/null | head -3
    HAS_WARNINGS=1
fi

# Check for missing CSRF token in forms
if grep -qE '<form[^>]*method\s*=\s*["\047](post|put|patch|delete)["\047]' "$FILE_PATH" 2>/dev/null; then
    FORM_LINES=$(grep -n '<form' "$FILE_PATH" 2>/dev/null | cut -d: -f1)
    for LINE in $FORM_LINES; do
        # Check next 5 lines for @csrf
        FORM_CONTENT=$(sed -n "${LINE},$((LINE+5))p" "$FILE_PATH")
        if ! echo "$FORM_CONTENT" | grep -qE '@csrf|csrf_field\(\)|<input.*_token'; then
            echo -e "${RED}ERROR: Form without CSRF token at line $LINE:${NC}"
            sed -n "${LINE}p" "$FILE_PATH"
            HAS_ERRORS=1
        fi
    done
fi

# Check for @method directive in PUT/PATCH/DELETE forms
if grep -qE 'method\s*=\s*["\047](put|patch|delete)["\047]' "$FILE_PATH" 2>/dev/null; then
    # HTML forms only support GET/POST, need @method
    FORM_LINES=$(grep -nE 'method\s*=\s*["\047](put|patch|delete)["\047]' "$FILE_PATH" 2>/dev/null | cut -d: -f1)
    for LINE in $FORM_LINES; do
        FORM_CONTENT=$(sed -n "${LINE},$((LINE+5))p" "$FILE_PATH")
        if ! echo "$FORM_CONTENT" | grep -qE '@method|method_field'; then
            echo -e "${YELLOW}WARNING: PUT/PATCH/DELETE form may need @method directive at line $LINE${NC}"
            HAS_WARNINGS=1
        fi
    done
fi

# Check for unclosed Blade directives
DIRECTIVES=(
    "@if:@endif"
    "@foreach:@endforeach"
    "@forelse:@endforelse"
    "@for:@endfor"
    "@while:@endwhile"
    "@switch:@endswitch"
    "@auth:@endauth"
    "@guest:@endguest"
    "@can:@endcan"
    "@cannot:@endcannot"
    "@section:@endsection"
    "@push:@endpush"
    "@prepend:@endprepend"
    "@component:@endcomponent"
    "@slot:@endslot"
)

for PAIR in "${DIRECTIVES[@]}"; do
    OPEN="${PAIR%%:*}"
    CLOSE="${PAIR##*:}"

    OPEN_COUNT=$(grep -c "$OPEN" "$FILE_PATH" 2>/dev/null || echo 0)
    CLOSE_COUNT=$(grep -c "$CLOSE" "$FILE_PATH" 2>/dev/null || echo 0)

    if [ "$OPEN_COUNT" -gt "$CLOSE_COUNT" ]; then
        echo -e "${RED}ERROR: Unclosed $OPEN directive (${OPEN_COUNT} open, ${CLOSE_COUNT} closed)${NC}"
        HAS_ERRORS=1
    fi
done

# Check for deprecated directives
DEPRECATED_DIRECTIVES=(
    "@inject"  # Use dependency injection instead
)

for DIR in "${DEPRECATED_DIRECTIVES[@]}"; do
    if grep -qE "^\\s*$DIR" "$FILE_PATH" 2>/dev/null; then
        echo -e "${YELLOW}WARNING: $DIR is discouraged - consider dependency injection${NC}"
        HAS_WARNINGS=1
    fi
done

# Check for JavaScript in onclick handlers (should use Alpine or Livewire)
if grep -qE 'onclick\s*=\s*["\047]' "$FILE_PATH" 2>/dev/null; then
    echo -e "${YELLOW}WARNING: Inline onclick handlers found - consider Alpine.js or Livewire:${NC}"
    grep -nE 'onclick\s*=\s*["\047]' "$FILE_PATH" 2>/dev/null | head -3
    HAS_WARNINGS=1
fi

# Check for inline styles (should use Tailwind or CSS classes)
INLINE_STYLE_COUNT=$(grep -cE 'style\s*=\s*["\047]' "$FILE_PATH" 2>/dev/null || echo 0)
if [ "$INLINE_STYLE_COUNT" -gt 3 ]; then
    echo -e "${YELLOW}WARNING: Multiple inline styles found ($INLINE_STYLE_COUNT) - consider CSS classes${NC}"
    HAS_WARNINGS=1
fi

# Summary
if [ $HAS_ERRORS -ne 0 ]; then
    echo -e "${RED}Blade lint failed with errors.${NC}"
    exit 2
fi

if [ $HAS_WARNINGS -ne 0 ]; then
    echo -e "${YELLOW}Blade lint passed with warnings.${NC}"
    exit 0
fi

echo -e "${GREEN}Blade lint passed.${NC}"
exit 0
