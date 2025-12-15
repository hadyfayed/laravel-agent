#!/bin/bash
# Laravel Agent Test Runner Hook
# Runs related tests when PHP files are modified

set -e

FILE_PATH="$1"

# Colors
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

# Exit if no file path
if [ -z "$FILE_PATH" ]; then
    exit 0
fi

# Only process PHP files
if [[ ! "$FILE_PATH" =~ \.php$ ]]; then
    exit 0
fi

# Skip if it's a test file itself (we'll run it directly)
IS_TEST_FILE=0
if [[ "$FILE_PATH" =~ tests/ ]]; then
    IS_TEST_FILE=1
fi

# Exit if file doesn't exist
if [ ! -f "$FILE_PATH" ]; then
    exit 0
fi

# Check if Pest or PHPUnit is available
PEST_BIN="vendor/bin/pest"
PHPUNIT_BIN="vendor/bin/phpunit"

if [ ! -f "$PEST_BIN" ] && [ ! -f "$PHPUNIT_BIN" ]; then
    echo -e "${YELLOW}No test runner found. Skipping tests.${NC}"
    exit 0
fi

# Determine test command
if [ -f "$PEST_BIN" ]; then
    TEST_CMD="$PEST_BIN"
else
    TEST_CMD="$PHPUNIT_BIN"
fi

echo -e "${BLUE}Test runner: Checking for related tests...${NC}"

# If it's a test file, run it directly
if [ $IS_TEST_FILE -eq 1 ]; then
    echo -e "${YELLOW}Running test file: $FILE_PATH${NC}"
    $TEST_CMD "$FILE_PATH" --colors=always 2>&1 || {
        echo -e "${RED}Tests failed!${NC}"
        exit 2  # Blocking error
    }
    echo -e "${GREEN}Tests passed!${NC}"
    exit 0
fi

# Extract class name from file
FILENAME=$(basename "$FILE_PATH" .php)

# Build list of possible test files
declare -a TEST_FILES=()

# Check common test locations
POSSIBLE_TESTS=(
    "tests/Feature/${FILENAME}Test.php"
    "tests/Unit/${FILENAME}Test.php"
    "tests/Feature/${FILENAME}FeatureTest.php"
    "tests/Unit/${FILENAME}UnitTest.php"
)

# For controllers, check feature tests
if [[ "$FILE_PATH" =~ Controllers/ ]]; then
    CONTROLLER_NAME="${FILENAME%Controller}"
    POSSIBLE_TESTS+=(
        "tests/Feature/${CONTROLLER_NAME}Test.php"
        "tests/Feature/${CONTROLLER_NAME}FeatureTest.php"
        "tests/Feature/Http/${FILENAME}Test.php"
    )
fi

# For models, check both unit and feature
if [[ "$FILE_PATH" =~ Models/ ]]; then
    POSSIBLE_TESTS+=(
        "tests/Unit/Models/${FILENAME}Test.php"
        "tests/Feature/Models/${FILENAME}Test.php"
    )
fi

# For services/actions
if [[ "$FILE_PATH" =~ (Services|Actions)/ ]]; then
    POSSIBLE_TESTS+=(
        "tests/Unit/Services/${FILENAME}Test.php"
        "tests/Unit/Actions/${FILENAME}Test.php"
    )
fi

# Check which test files exist
for TEST_FILE in "${POSSIBLE_TESTS[@]}"; do
    if [ -f "$TEST_FILE" ]; then
        TEST_FILES+=("$TEST_FILE")
    fi
done

# Also search for tests that might reference this class
if [ ${#TEST_FILES[@]} -eq 0 ]; then
    # Search for test files that import this class
    FOUND_TESTS=$(grep -rl "use.*\\\\${FILENAME}" tests/ 2>/dev/null | head -5 || true)
    if [ -n "$FOUND_TESTS" ]; then
        while IFS= read -r line; do
            TEST_FILES+=("$line")
        done <<< "$FOUND_TESTS"
    fi
fi

# Run found tests
if [ ${#TEST_FILES[@]} -gt 0 ]; then
    echo -e "${YELLOW}Running related tests:${NC}"
    for TEST_FILE in "${TEST_FILES[@]}"; do
        echo "  - $TEST_FILE"
    done

    # Run tests with filter
    $TEST_CMD "${TEST_FILES[@]}" --colors=always 2>&1 || {
        echo -e "${RED}Tests failed!${NC}"
        exit 2  # Blocking error
    }
    echo -e "${GREEN}All related tests passed!${NC}"
else
    echo -e "${YELLOW}No related tests found for: $FILENAME${NC}"
fi

exit 0
