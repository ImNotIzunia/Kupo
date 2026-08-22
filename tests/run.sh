#!/usr/bin/env bash

set -u

# ============================================================
# Configuration
# ============================================================

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
PROJECT_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd -P)"

FUNCTIONS_DIR="$PROJECT_DIR/functions"
TESTS_DIR="$PROJECT_DIR/tests"

# ============================================================
# Colors
# ============================================================

if [[ -t 1 ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    BOLD='\033[1m'
    RESET='\033[0m'
else
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    BOLD=''
    RESET=''
fi

# ============================================================
# Counters
# ============================================================

ERRORS=0

# ============================================================
# Helpers
# ============================================================

print_header() {
    echo
    echo -e "${BOLD}${BLUE}============================================================${RESET}"
    echo -e "${BOLD}${BLUE} $1${RESET}"
    echo -e "${BOLD}${BLUE}============================================================${RESET}"
    echo
}

success() {
    echo -e "  ${GREEN}✓${RESET} $1"
}

failure() {
    echo -e "  ${RED}✗${RESET} $1"
    ERRORS=$((ERRORS + 1))
}

warning() {
    echo -e "  ${YELLOW}!${RESET} $1"
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# ============================================================
# Check dependencies
# ============================================================

check_dependencies() {
    print_header "Checking dependencies"

    local dependencies=(
        bash
        bats
        jq
        shellcheck
        zip
        unzip
    )

    local dependency

    for dependency in "${dependencies[@]}"; do
        if command_exists "$dependency"; then
            success "$dependency"
        else
            failure "$dependency is not installed"
        fi
    done
}

# ============================================================
# Check project structure
# ============================================================

check_structure() {
    print_header "Checking project structure"

    if [[ -d "$FUNCTIONS_DIR" ]]; then
        success "functions/ directory"
    else
        failure "functions/ directory not found"
    fi

    if [[ -d "$TESTS_DIR" ]]; then
        success "tests/ directory"
    else
        failure "tests/ directory not found"
    fi
}

# ============================================================
# Bash syntax check
# ============================================================

check_bash_syntax() {
    print_header "Checking Bash syntax"

    local files=()

    while IFS= read -r -d '' file; do
        files+=("$file")
    done < <(
        find "$PROJECT_DIR" \
            -type f \
            -name '*.sh' \
            -not -path "$TESTS_DIR/*" \
            -print0
    )

    if [[ "${#files[@]}" -eq 0 ]]; then
        warning "No Bash files found"
        return
    fi

    local file
    local relative_path

    for file in "${files[@]}"; do
        relative_path="${file#"$PROJECT_DIR"/}"

        if bash -n "$file"; then
            success "$relative_path"
        else
            failure "$relative_path"
        fi
    done
}

# ============================================================
# ShellCheck
# ============================================================

run_shellcheck() {
    print_header "Running ShellCheck"

    local files=()

    while IFS= read -r -d '' file; do
        files+=("$file")
    done < <(
        find "$PROJECT_DIR" \
            -type f \
            -name '*.sh' \
            -not -path "$TESTS_DIR/*" \
            -print0
    )

    if [[ "${#files[@]}" -eq 0 ]]; then
        warning "No Bash files found"
        return
    fi

    local file
    local relative_path

    for file in "${files[@]}"; do
        relative_path="${file#"$PROJECT_DIR"/}"

        if shellcheck -x "$file"; then
            success "$relative_path"
        else
            failure "$relative_path"
        fi
    done
}

# ============================================================
# Bats tests
# ============================================================

run_bats() {
    print_header "Running Bats tests"

    local test_files=()

    while IFS= read -r -d '' file; do
        test_files+=("$file")
    done < <(
        find "$TESTS_DIR" \
            -type f \
            -name '*.bat' \
            -print0
    )

    if [[ "${#test_files[@]}" -eq 0 ]]; then
        warning "No Bat test files found"
        return
    fi

    local file
    local relative_path

    for file in "${test_files[@]}"; do
        relative_path="${file#"$PROJECT_DIR"/}"

        echo
        echo -e "${BOLD}Running $relative_path${RESET}"
        echo

        if bats "$file"; then
            success "$relative_path"
        else
            failure "$relative_path"
        fi
    done
}

# ============================================================
# Main
# ============================================================

main() {
    echo
    echo -e "${BOLD}Project: $PROJECT_DIR${RESET}"

    check_dependencies

    if (( ERRORS > 0 )); then
        print_header "Result"
        echo -e "${RED}${BOLD}Checks aborted because required dependencies or directories are missing.${RESET}"
        exit 1
    fi

    check_structure

    if (( ERRORS > 0 )); then
        print_header "Result"
        echo -e "${RED}${BOLD}Checks aborted because the project structure is invalid.${RESET}"
        exit 1
    fi

    check_bash_syntax
    run_shellcheck
    run_bats

    print_header "Result"

    if (( ERRORS > 0 )); then
        echo -e "${RED}${BOLD}${ERRORS} check(s) failed.${RESET}"
        exit 1
    fi

    echo -e "${GREEN}${BOLD}All checks passed.${RESET}"
    exit 0
}

main "$@"