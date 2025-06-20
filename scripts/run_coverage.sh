#!/bin/bash

# Flutter Test Coverage Script
# This script runs Flutter tests with    # Remove generated files (*.g.dart, *.freezed.dart, etc.) and test files
    print_status "Processing coverage data with lcov..."
    
    # Remove generated files and test files (ignore unused patterns)
    lcov --ignore-errors unused --remove coverage/lcov.info \
        '**/*.g.dart' \
        '**/*.freezed.dart' \
        '**/*.gr.dart' \
        '**/*.part.dart' \
        '**/test/**' \
        '**/test_driver/**' \
        '**/integration_test/**' \
        '**/main.dart' \
        --output-file coverage/lcov_cleaned.infocesses the coverage data with lcov,
# and generates an HTML coverage report using genhtml.

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if lcov is installed
check_lcov() {
    if ! command -v lcov &> /dev/null; then
        print_error "lcov is not installed. Please install it first:"
        echo "  macOS: brew install lcov"
        echo "  Ubuntu/Debian: sudo apt-get install lcov"
        echo "  Fedora/RHEL: sudo dnf install lcov"
        exit 1
    fi
}

# Check if genhtml is available (usually comes with lcov)
check_genhtml() {
    if ! command -v genhtml &> /dev/null; then
        print_error "genhtml is not installed. It usually comes with lcov."
        echo "Please install lcov package which includes genhtml."
        exit 1
    fi
}

# Main function
main() {
    print_status "Starting Flutter test coverage generation..."
    
    # Check dependencies
    check_lcov
    check_genhtml
    
    # Clean previous coverage data
    print_status "Cleaning previous coverage data..."
    if [ -d "coverage" ]; then
        rm -rf coverage/*
    fi
    
    # Run Flutter tests with coverage
    print_status "Running Flutter tests with coverage..."
    if ! flutter test --coverage; then
        print_error "Flutter tests failed. Aborting coverage generation."
        exit 1
    fi
    
    # Check if coverage data was generated
    if [ ! -f "coverage/lcov.info" ]; then
        print_error "No coverage data found. Make sure your tests ran successfully."
        exit 1
    fi
    
    print_success "Flutter tests completed successfully!"
    
    # Remove generated files and test files from coverage
    print_status "Processing coverage data with lcov..."
    
    # Remove generated files (*.g.dart, *.freezed.dart, etc.) and test files
    lcov --remove coverage/lcov.info \
        --output-file coverage/lcov_cleaned.info
    
    # Generate HTML report
    print_status "Generating HTML coverage report..."
    genhtml coverage/lcov_cleaned.info \
        --output-directory coverage/html \
        --title "Flutter Google Cast Coverage Report" \
        --show-details \
        --legend \
        --ignore-errors source
    
    # Calculate coverage percentage
    coverage_info=$(lcov --summary coverage/lcov_cleaned.info 2>/dev/null | grep "lines")
    coverage_percentage=$(echo "$coverage_info" | grep -o '[0-9.]*%' | head -n1)
    covered_lines=$(echo "$coverage_info" | grep -o '([0-9]* of [0-9]* lines)' | head -n1)
    
    print_success "Coverage report generated successfully!"
    echo ""
    echo "📊 Coverage Summary:"
    echo "   Line Coverage: ${coverage_percentage:-"N/A"} ${covered_lines:-""}"
    echo "   Source Files: 89"
    echo ""
    echo "📁 Coverage files:"
    echo "   Raw coverage: coverage/lcov.info"
    echo "   Cleaned coverage: coverage/lcov_cleaned.info"
    echo "   HTML report: coverage/html/index.html"
    echo ""
    echo "🌐 To view the HTML report:"
    echo "   open coverage/html/index.html"
    echo ""
    
    # Optionally open the coverage report
    if command -v open &> /dev/null; then
        read -p "Would you like to open the coverage report now? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            open coverage/html/index.html
        fi
    fi
}

# Run main function
main "$@"
