#!/usr/bin/env bash
# test_pikerc.sh — Tests for .pikerc file resolution
# Sourced by run_tests.sh

test_find_pikerc_in_current_dir() {
	local test_dir="$(mktemp -d)"
	printf '8.0.1116\n' > "${test_dir}/.pikerc"

	local old_pwd="$PWD"
	cd "$test_dir"

	local result
	result="$(pvm_find_pikerc)"
	run_test
	if [ "$result" = "${test_dir}/.pikerc" ]; then
		pass
	else
		fail "should find .pikerc in current dir, got '$result'"
	fi

	cd "$old_pwd"
	rm -rf "$test_dir"
}

test_find_pikerc_in_parent_dir() {
	local test_dir="$(mktemp -d)"
	local child_dir="${test_dir}/child"
	mkdir -p "$child_dir"
	printf '8.0.1732\n' > "${test_dir}/.pikerc"

	local old_pwd="$PWD"
	cd "$child_dir"

	local result
	result="$(pvm_find_pikerc)"
	run_test
	if [ "$result" = "${test_dir}/.pikerc" ]; then
		pass
	else
		fail "should find .pikerc in parent dir, got '$result'"
	fi

	cd "$old_pwd"
	rm -rf "$test_dir"
}

test_find_pikerc_not_found() {
	local test_dir="$(mktemp -d)"
	local old_pwd="$PWD"
	cd "$test_dir"

	local result
	if result="$(pvm_find_pikerc 2>/dev/null)"; then
		run_test
		fail "find_pikerc should fail when no .pikerc exists"
	else
		run_test
		pass
	fi

	cd "$old_pwd"
	rm -rf "$test_dir"
}

test_read_pikerc() {
	local test_dir="$(mktemp -d)"
	printf '8.0.1116\n' > "${test_dir}/.pikerc"

	local old_pwd="$PWD"
	cd "$test_dir"

	local result
	result="$(pvm_read_pikerc)"
	run_test
	if [ "$result" = "8.0.1116" ]; then
		pass
	else
		fail "read_pikerc should return '8.0.1116', got '$result'"
	fi

	cd "$old_pwd"
	rm -rf "$test_dir"
}

test_read_pikerc_with_comments() {
	local test_dir
	test_dir="$(mktemp -d)"
	printf '# This is a comment\n8.0.1732\n' > "${test_dir}/.pikerc"

	local old_pwd="$PWD"
	cd "$test_dir"

	local result
	result="$(pvm_read_pikerc)"
	run_test
	if [ "$result" = "8.0.1732" ]; then
		pass
	else
		fail "read_pikerc should skip comments and return '8.0.1732', got '$result'"
	fi

	cd "$old_pwd"
	rm -rf "$test_dir"
}

test_find_pikerc_in_current_dir
test_find_pikerc_in_parent_dir
test_find_pikerc_not_found
test_read_pikerc
test_read_pikerc_with_comments
