#!/bin/bash
# Laravel Agent Security Scan Hook
# Scans files for potential secrets and security issues

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

# Only scan PHP, JS, env files
if [[ ! "$FILE_PATH" =~ \.(php|js|ts|env|json|yml|yaml)$ ]]; then
    exit 0
fi

# Skip vendor and node_modules
if [[ "$FILE_PATH" =~ (vendor|node_modules)/ ]]; then
    exit 0
fi

# Exit if file doesn't exist
if [ ! -f "$FILE_PATH" ]; then
    exit 0
fi

HAS_ISSUES=0

echo -e "${YELLOW}Security scan: $FILE_PATH${NC}"

# Secret patterns to detect
declare -a SECRET_PATTERNS=(
    # API Keys
    "api[_-]?key['\"]?\s*[=:]\s*['\"][a-zA-Z0-9]{20,}"
    "secret[_-]?key['\"]?\s*[=:]\s*['\"][a-zA-Z0-9]{20,}"

    # AWS
    "AKIA[0-9A-Z]{16}"
    "aws[_-]?secret[_-]?access[_-]?key"

    # Stripe
    "sk_live_[a-zA-Z0-9]{24,}"
    "pk_live_[a-zA-Z0-9]{24,}"
    "rk_live_[a-zA-Z0-9]{24,}"

    # GitHub/GitLab
    "ghp_[a-zA-Z0-9]{36}"
    "gho_[a-zA-Z0-9]{36}"
    "glpat-[a-zA-Z0-9-]{20,}"

    # Slack
    "xox[baprs]-[a-zA-Z0-9-]{10,}"

    # JWT/Bearer
    "eyJ[a-zA-Z0-9_-]*\.eyJ[a-zA-Z0-9_-]*\.[a-zA-Z0-9_-]*"

    # Private keys
    "-----BEGIN (RSA |DSA |EC |OPENSSH )?PRIVATE KEY-----"

    # Passwords in code
    "password['\"]?\s*[=:]\s*['\"][^'\"]{8,}"

    # Database URLs
    "mysql://[^:]+:[^@]+@"
    "postgres://[^:]+:[^@]+@"
    "mongodb://[^:]+:[^@]+@"

    # Twilio
    "SK[a-f0-9]{32}"

    # SendGrid
    "SG\.[a-zA-Z0-9_-]{22}\.[a-zA-Z0-9_-]{43}"

    # Mailgun
    "key-[a-f0-9]{32}"
)

# Check each pattern
for pattern in "${SECRET_PATTERNS[@]}"; do
    if grep -qiE "$pattern" "$FILE_PATH" 2>/dev/null; then
        echo -e "${RED}POTENTIAL SECRET DETECTED:${NC}"
        grep -niE "$pattern" "$FILE_PATH" 2>/dev/null | head -3
        HAS_ISSUES=1
    fi
done

# Check for hardcoded IPs (not localhost)
if grep -qE '\b(?!127\.0\.0\.1|0\.0\.0\.0|localhost)[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\b' "$FILE_PATH" 2>/dev/null; then
    # Skip if in comments or config files
    if [[ ! "$FILE_PATH" =~ \.env ]]; then
        MATCHES=$(grep -nE '\b[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\b' "$FILE_PATH" 2>/dev/null | grep -v "127.0.0.1\|0.0.0.0\|localhost\|//" | head -3)
        if [ -n "$MATCHES" ]; then
            echo -e "${YELLOW}Hardcoded IP address found:${NC}"
            echo "$MATCHES"
        fi
    fi
fi

# Check for debug/dump functions in PHP
if [[ "$FILE_PATH" =~ \.php$ ]]; then
    if grep -qE '\b(dd|dump|var_dump|print_r|die)\s*\(' "$FILE_PATH" 2>/dev/null; then
        echo -e "${YELLOW}Debug function found (remove before production):${NC}"
        grep -nE '\b(dd|dump|var_dump|print_r|die)\s*\(' "$FILE_PATH" 2>/dev/null | head -3
    fi

    # Check for eval()
    if grep -qE '\beval\s*\(' "$FILE_PATH" 2>/dev/null; then
        echo -e "${RED}DANGEROUS: eval() found - potential code injection:${NC}"
        grep -nE '\beval\s*\(' "$FILE_PATH" 2>/dev/null
        HAS_ISSUES=1
    fi
fi

# Check .env files are not being committed
if [[ "$FILE_PATH" =~ \.env$ ]] && [[ ! "$FILE_PATH" =~ \.env\.example$ ]]; then
    echo -e "${RED}WARNING: .env file should not be committed!${NC}"
    HAS_ISSUES=1
fi

if [ $HAS_ISSUES -ne 0 ]; then
    echo -e "${RED}Security issues detected. Review before committing.${NC}"
    exit 2  # Blocking error
fi

echo -e "${GREEN}Security scan passed.${NC}"
exit 0
