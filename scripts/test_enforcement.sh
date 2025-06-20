#!/bin/bash

# Test enforcement script for Flutter Chrome Cast
# This script can be run locally or in CI to enforce testing requirements

set -e

echo "🧪 Running Flutter Chrome Cast Test Enforcement"
echo "================================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if test directory exists
if [ ! -d "test" ]; then
    echo -e "${RED}❌ Error: No test directory found!${NC}"
    echo "Tests are required for this project."
    echo "Please create tests in the 'test' directory."
    exit 1
fi

# Check if test files exist
test_files=$(find test -name "*.dart" -type f | wc -l)
if [ "$test_files" -eq 0 ]; then
    echo -e "${RED}❌ Error: No test files found!${NC}"
    echo "At least one test file is required in the test directory."
    exit 1
fi

echo -e "${GREEN}✅ Found $test_files test files${NC}"

# Run the tests
echo -e "${YELLOW}🔄 Running tests...${NC}"
flutter test

# Check test results
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ All tests passed!${NC}"
else
    echo -e "${RED}❌ Some tests failed!${NC}"
    exit 1
fi

# Optional: Check for test coverage
if command -v lcov &> /dev/null; then
    echo -e "${YELLOW}📊 Generating test coverage...${NC}"
    flutter test --coverage
    
    if [ -f "coverage/lcov.info" ]; then
        # Calculate coverage percentage
        coverage_percent=$(lcov --summary coverage/lcov.info 2>/dev/null | grep -oE 'lines[^:]*: [0-9.]+%' | grep -oE '[0-9.]+' | head -1)
        
        if [ ! -z "$coverage_percent" ]; then
            echo -e "${GREEN}📈 Test coverage: $coverage_percent%${NC}"
            
            # Uncomment the lines below to enforce minimum coverage
            # MINIMUM_COVERAGE=80
            # if (( $(echo "$coverage_percent < $MINIMUM_COVERAGE" | bc -l) )); then
            #     echo -e "${RED}❌ Error: Test coverage is below $MINIMUM_COVERAGE% (found: $coverage_percent%)${NC}"
            #     exit 1
            # fi
        fi
    fi
else
    echo -e "${YELLOW}⚠️  lcov not found. Install it to get coverage reports.${NC}"
fi

# Check for specific test patterns (optional)
echo -e "${YELLOW}🔍 Checking test patterns...${NC}"

# Check if critical components have tests
critical_files=("cast_context" "discovery" "session" "media")
missing_tests=()

for file in "${critical_files[@]}"; do
    if ! find test -name "*${file}*test.dart" -type f | grep -q .; then
        missing_tests+=("$file")
    fi
done

if [ ${#missing_tests[@]} -gt 0 ]; then
    echo -e "${YELLOW}⚠️  Warning: Missing tests for critical components:${NC}"
    for missing in "${missing_tests[@]}"; do
        echo -e "${YELLOW}   - $missing${NC}"
    done
    echo -e "${YELLOW}   Consider adding tests for these components.${NC}"
fi

echo -e "${GREEN}🎉 Test enforcement completed successfully!${NC}"
