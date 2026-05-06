#!/usr/bin/env bash
# test_fish.sh — Tests for Fish shell integration (_fish subcommand)
# Run via: bash tests/run_tests.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PVM_DIR="${TEST_PVM_DIR:-${SCRIPT_DIR}/fixtures/pvm_test_$$}"

export PVM_DIR
export PVM_AUTO_USE="false"

# Create a mock Pike version
# shellcheck disable=SC2317
create_mock_version() {
	local version="$1"
	local version_dir="$PVM_DIR/versions/$version"
	mkdir -p "$version_dir/bin" "$version_dir/build/lib/modules" "$version_dir/build/include"
	touch "$version_dir/bin/pike"
	touch "$version_dir/master.pike"
	chmod +x "$version_dir/bin/pike"
}

# Cleanup
# shellcheck disable=SC2317
cleanup() {
	if [ -d "$PVM_DIR" ]; then
		rm -rf "$PVM_DIR"
	fi
}
trap cleanup EXIT

# Source pvm
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/../pvm.sh"

# Test counter - use simple assignment to avoid set -e issues with ((x++))
passed=0
failed=0

test_equals() {
	local name="$1"
	local expected="$2"
	local actual="$3"

	if [ "$expected" = "$actual" ]; then
		echo "PASS: $name"
		passed=$((passed + 1))
	else
		echo "FAIL: $name"
		echo "  Expected: $expected"
		echo "  Actual:   $actual"
		failed=$((failed + 1))
	fi
}

test_output_contains() {
	local name="$1"
	local output="$2"
	local pattern="$3"

	if echo "$output" | grep -qF "$pattern"; then
		echo "PASS: $name"
		passed=$((passed + 1))
	else
		echo "FAIL: $name"
		echo "  Expected output to contain: $pattern"
		echo "  Actual output:"
		while read -r line; do echo "    $line"; done <<< "$output"
		failed=$((failed + 1))
	fi
}

test_output_not_contains() {
	local name="$1"
	local output="$2"
	local pattern="$3"

	if ! echo "$output" | grep -qF "$pattern"; then
		echo "PASS: $name"
		passed=$((passed + 1))
	else
		echo "FAIL: $name"
		echo "  Expected output NOT to contain: $pattern"
		echo "  Actual output:"
		while read -r line; do echo "    $line"; done <<< "$output"
		failed=$((failed + 1))
	fi
}

# Setup
mkdir -p "$PVM_DIR/versions"
create_mock_version "8.0.1116"
create_mock_version "8.0.1732"

echo "=== Testing pvm _fish subcommand ==="
echo ""

# Test: _fish use outputs key=value pairs
echo "--- Test: _fish use outputs key=value pairs ---"
output="$(pvm _fish use 8.0.1116 2>&1)" || true
test_output_contains "_fish use PVM_BIN" "$output" "PVM_BIN="
test_output_contains "_fish use PVM_PIKE" "$output" "PVM_PIKE="
test_output_contains "_fish use PIKE_MODULE_PATH" "$output" "PIKE_MODULE_PATH="
test_output_contains "_fish use PVM_PIKE_HOME" "$output" "PVM_PIKE_HOME="
test_output_contains "_fish use PVM_PIKE_VERSION" "$output" "PVM_PIKE_VERSION=8.0.1116"
test_output_contains "_fish use PVM_PATH" "$output" "PVM_PATH="

echo ""
echo "--- Test: _fish use with version path ---"
output="$(pvm _fish use 8.0.1116 2>&1)" || true
test_output_contains "PVM_BIN contains version" "$output" "$PVM_DIR/versions/8.0.1116/bin"
test_output_contains "PVM_PIKE contains pike" "$output" "$PVM_DIR/versions/8.0.1116/bin/pike"

echo ""
echo "--- Test: _fish deactivate outputs vars to unset ---"
output="$(pvm _fish deactivate 2>&1)" || true
test_output_contains "_fish deactivate PVM_BIN" "$output" "PVM_BIN"
test_output_contains "_fish deactivate PVM_PIKE" "$output" "PVM_PIKE"
test_output_contains "_fish deactivate PIKE_MODULE_PATH" "$output" "PIKE_MODULE_PATH"
test_output_contains "_fish deactivate PVM_PIKE_HOME" "$output" "PVM_PIKE_HOME"
test_output_contains "_fish deactivate PVM_PIKE_VERSION" "$output" "PVM_PIKE_VERSION"

echo ""
echo "--- Test: _fish deactivate outputs PVM_PATH ---"
output="$(pvm _fish deactivate 2>&1)" || true
test_output_contains "_fish deactivate PVM_PATH" "$output" "PVM_PATH="

echo ""
echo "--- Test: _fish use with not-installed version fails ---"
status=0
output="$(pvm _fish use 9.9.9999 2>&1)" || status=$?
if [ "$status" -ne 0 ]; then
	echo "PASS: _fish use fails for non-installed version"
	passed=$((passed + 1))
else
	echo "FAIL: _fish use should fail for non-installed version"
	failed=$((failed + 1))
fi

echo ""
echo "--- Test: _fish with invalid subcommand fails ---"
status=0
output="$(pvm _fish invalid 2>&1)" || status=$?
if [ "$status" -ne 0 ]; then
	echo "PASS: _fish with invalid subcommand fails"
	passed=$((passed + 1))
else
	echo "FAIL: _fish with invalid subcommand should fail"
	failed=$((failed + 1))
fi

echo ""
echo "=== Summary ==="
echo "Passed: $passed"
echo "Failed: $failed"
echo ""

if [ "$failed" -gt 0 ]; then
	echo "Some tests failed!"
	exit 1
fi

echo "All tests passed!"
