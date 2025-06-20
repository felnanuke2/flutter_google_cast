#!/bin/bash

# Quick Coverage Script
# This script runs tests with coverage and opens the HTML report

set -e

echo "🧪 Running tests with coverage..."
flutter test --coverage

echo "📊 Processing coverage data..."
# Check if lcov is installed
if ! command -v lcov &> /dev/null; then
    echo "❌ lcov is not installed. Please install it:"
    echo "   macOS: brew install lcov"
    echo "   Ubuntu: sudo apt-get install lcov"
    exit 1
fi

# Process coverage data
lcov --ignore-errors unused --remove coverage/lcov.info \
    '**/*.g.dart' \
    '**/*.freezed.dart' \
    '**/*.gr.dart' \
    '**/*.part.dart' \
    '**/test/**' \
    '**/test_driver/**' \
    '**/integration_test/**' \
    '**/main.dart' \
    --output-file coverage/lcov_cleaned.info

# Generate HTML report
genhtml coverage/lcov_cleaned.info -o coverage/html

# Calculate coverage percentage
coverage_percent=$(lcov --summary coverage/lcov_cleaned.info | grep -oP 'lines......: \K\d+\.\d+' | head -1)
echo "✅ Coverage: $coverage_percent%"

# Open the HTML report (macOS/Linux)
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "🌐 Opening coverage report in browser..."
    open coverage/html/index.html
elif command -v xdg-open &> /dev/null; then
    echo "🌐 Opening coverage report in browser..."
    xdg-open coverage/html/index.html
else
    echo "📁 Coverage report generated at: coverage/html/index.html"
fi
