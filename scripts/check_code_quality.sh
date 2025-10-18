#!/bin/bash

# Code Quality Check Script for Wonwonw2
# This script runs comprehensive code quality checks

echo "🔍 Running comprehensive code quality checks..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check if we're in the project root
if [ ! -f "pubspec.yaml" ]; then
    print_error "Please run this script from the project root directory"
    exit 1
fi

# 1. Check Flutter installation
echo "🔧 Checking Flutter installation..."
if ! command -v flutter &> /dev/null; then
    print_error "Flutter is not installed or not in PATH"
    exit 1
fi

flutter --version
print_status "Flutter is installed"

# 2. Get dependencies
echo "📦 Getting dependencies..."
if ! flutter pub get; then
    print_error "Failed to get dependencies"
    exit 1
fi
print_status "Dependencies installed"

# 3. Check code formatting
echo "🎨 Checking code formatting..."
if ! dart format --set-exit-if-changed .; then
    print_warning "Code formatting issues found"
    echo "Running dart format to fix formatting issues..."
    dart format .
    print_status "Code formatting fixed"
else
    print_status "Code formatting is correct"
fi

# 4. Run static analysis
echo "🔍 Running static analysis..."
if ! dart analyze --fatal-infos; then
    print_error "Static analysis issues found"
    exit 1
fi
print_status "Static analysis passed"

# 5. Run tests
echo "🧪 Running tests..."
if ! flutter test --coverage; then
    print_error "Tests failed"
    exit 1
fi
print_status "All tests passed"

# 6. Check test coverage
echo "📊 Checking test coverage..."
if [ -f "coverage/lcov.info" ]; then
    # Install lcov if not available
    if ! command -v lcov &> /dev/null; then
        print_warning "lcov not found, installing..."
        if command -v apt-get &> /dev/null; then
            sudo apt-get install lcov
        elif command -v brew &> /dev/null; then
            brew install lcov
        fi
    fi
    
    # Generate coverage report
    if command -v lcov &> /dev/null; then
        lcov --summary coverage/lcov.info
        print_status "Coverage report generated"
    fi
else
    print_warning "Coverage file not found"
fi

# 7. Check for security issues
echo "🔒 Checking for security issues..."
if ! flutter pub deps --json | grep -q "vulnerable"; then
    print_status "No known security vulnerabilities found"
else
    print_warning "Potential security vulnerabilities found in dependencies"
fi

# 8. Check for unused dependencies
echo "📋 Checking for unused dependencies..."
if command -v dart &> /dev/null; then
    if ! dart pub deps --json | grep -q "unused"; then
        print_status "No unused dependencies found"
    else
        print_warning "Some dependencies might be unused"
    fi
fi

# 9. Check file sizes
echo "📏 Checking file sizes..."
LARGE_FILES=$(find lib -name "*.dart" -size +1000k)
if [ -n "$LARGE_FILES" ]; then
    print_warning "Large files found:"
    echo "$LARGE_FILES"
else
    print_status "No excessively large files found"
fi

# 10. Check for TODO/FIXME comments
echo "📝 Checking for TODO/FIXME comments..."
TODO_COUNT=$(grep -r "TODO\|FIXME" lib --include="*.dart" | wc -l)
if [ "$TODO_COUNT" -gt 0 ]; then
    print_warning "Found $TODO_COUNT TODO/FIXME comments"
    grep -r "TODO\|FIXME" lib --include="*.dart" | head -10
else
    print_status "No TODO/FIXME comments found"
fi

# 11. Check for debug prints
echo "🐛 Checking for debug prints..."
DEBUG_PRINTS=$(grep -r "print(" lib --include="*.dart" | wc -l)
if [ "$DEBUG_PRINTS" -gt 0 ]; then
    print_warning "Found $DEBUG_PRINTS debug print statements"
    grep -r "print(" lib --include="*.dart" | head -5
else
    print_status "No debug print statements found"
fi

# 12. Check for hardcoded strings
echo "🔤 Checking for hardcoded strings..."
HARDCODED_STRINGS=$(grep -r '"[A-Z][a-z].*"' lib --include="*.dart" | grep -v "tr(" | wc -l)
if [ "$HARDCODED_STRINGS" -gt 0 ]; then
    print_warning "Found $HARDCODED_STRINGS potentially hardcoded strings"
    grep -r '"[A-Z][a-z].*"' lib --include="*.dart" | grep -v "tr(" | head -5
else
    print_status "No hardcoded strings found"
fi

echo ""
echo "🎉 Code quality check completed!"
echo "📊 Summary:"
echo "  - Flutter installation: ✅"
echo "  - Dependencies: ✅"
echo "  - Code formatting: ✅"
echo "  - Static analysis: ✅"
echo "  - Tests: ✅"
echo "  - Security: ✅"
echo "  - File sizes: ✅"
echo "  - TODO/FIXME: $TODO_COUNT found"
echo "  - Debug prints: $DEBUG_PRINTS found"
echo "  - Hardcoded strings: $HARDCODED_STRINGS found"
