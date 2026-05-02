#!/usr/bin/env bash
# run_tests.sh — Test runner for pvm
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PVM_DIR_BACKUP="${PVM_DIR:-}"

# Counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0
FAILURES=""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RESET='\033[0m'

pass() { TESTS_PASSED=$((TESTS_PASSED + 1)); }
fail() {
	TESTS_FAILED=$((TESTS_FAILED + 1))
	FAILURES="${FAILURES}\n  - $1"
	printf "  ${RED}FAIL${RESET}: %s\n" "$1"
}
run_test() { TESTS_RUN=$((TESTS_RUN + 1)); }

# Setup: create a temporary PVM_DIR for testing
export PVM_DIR="$(mktemp -d)"
mkdir -p "${PVM_DIR}/versions"
mkdir -p "${PVM_DIR}/alias"
mkdir -p "${PVM_DIR}/.cache/bin"

# Source pvm.sh
# shellcheck source=/dev/null
. "${SCRIPT_DIR}/../pvm.sh"

cleanup() {
	# Restore PVM_DIR
	if [ -n "${PVM_DIR:-}" ]; then
		rm -rf "${PVM_DIR}"
	fi
	if [ -n "${PVM_DIR_BACKUP:-}" ]; then
		export PVM_DIR="$PVM_DIR_BACKUP"
	else
		unset PVM_DIR 2>/dev/null || true
	fi
}
trap cleanup EXIT

# Run individual test files
printf "${YELLOW}Running pvm tests...${RESET}\n\n"

for test_file in "${SCRIPT_DIR}"/test_*.sh; do
	[ -f "$test_file" ] || continue
	printf "${YELLOW}--- %s ---${RESET}\n" "$(basename "$test_file")"
	# shellcheck source=/dev/null
	. "$test_file"
	printf "\n"
done

set +euo pipefail

# Summary
printf "\n${YELLOW}======================${RESET}\n"
printf "Tests run:    %d\n" "$TESTS_RUN"
printf "${GREEN}Passed:       %d${RESET}\n" "$TESTS_PASSED"
if [ "$TESTS_FAILED" -gt 0 ]; then
	printf "${RED}Failed:       %d${RESET}\n" "$TESTS_FAILED"
	printf "\nFailures:\n"
	printf '%b\n' "$FAILURES"
	exit 1
else
	printf "Failed:       0\n"
fi

printf "\n${GREEN}All tests passed!${RESET}\n"