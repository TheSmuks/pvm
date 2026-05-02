#!/usr/bin/env bash
# test_version.sh — Tests for version parsing and comparison
# Sourced by run_tests.sh

test_parse_version_full() {
	local result
	result="$(pvm_parse_version "8.0.1116")"
	run_test
	if [ "$result" = "8 0 1116" ]; then
		pass
	else
		fail "pvm_parse_version '8.0.1116' should be '8 0 1116', got '$result'"
	fi
}

test_parse_version_with_v_prefix() {
	local result
	result="$(pvm_parse_version "v8.0.1116")"
	run_test
	if [ "$result" = "8 0 1116" ]; then
		pass
	else
		fail "pvm_parse_version 'v8.0.1116' should be '8 0 1116', got '$result'"
	fi
}

test_parse_version_major_minor_only() {
	local result
	result="$(pvm_parse_version "8.0")"
	run_test
	if [ "$result" = "8 0 0" ]; then
		pass
	else
		fail "pvm_parse_version '8.0' should be '8 0 0', got '$result'"
	fi
}

test_version_compare_equal() {
	run_test
	local rc=0
	pvm_version_compare "8.0.1116" "8.0.1116" || rc=$?
	if [ "$rc" -eq 0 ]; then
		pass
	else
		fail "8.0.1116 should equal 8.0.1116"
	fi
}

test_version_compare_greater() {
	run_test
	local rc=0
	pvm_version_compare "8.0.1732" "8.0.1116" || rc=$?
	if [ "$rc" -eq 1 ]; then
		pass
	else
		fail "8.0.1732 should be greater than 8.0.1116"
	fi
}

test_version_compare_lesser() {
	run_test
	local rc=0
	pvm_version_compare "8.0.1116" "8.0.1732" || rc=$?
	if [ "$rc" -eq 2 ]; then
		pass
	else
		fail "8.0.1116 should be less than 8.0.1732"
	fi
}

test_version_compare_different_major() {
	run_test
	local rc=0
	pvm_version_compare "9.0.0" "8.0.1116" || rc=$?
	if [ "$rc" -eq 1 ]; then
		pass
	else
		fail "9.0.0 should be greater than 8.0.1116"
	fi
}

test_version_major_minor() {
	local result
	result="$(pvm_version_major_minor "8.0.1116")"
	run_test
	if [ "$result" = "8.0" ]; then
		pass
	else
		fail "pvm_version_major_minor '8.0.1116' should be '8.0', got '$result'"
	fi
}

test_parse_version_full
test_parse_version_with_v_prefix
test_parse_version_major_minor_only
test_version_compare_equal
test_version_compare_greater
test_version_compare_lesser
test_version_compare_different_major
test_version_major_minor
