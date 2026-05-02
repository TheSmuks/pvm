#!/usr/bin/env bash
# test_ls.sh — Tests for ls and ls-remote
# Sourced by run_tests.sh

# Create a fake Pike installation
setup_fake() {
	local version="$1"
	local version_path="${PVM_DIR}/versions/${version}"
	mkdir -p "${version_path}/bin"
	mkdir -p "${version_path}/build"
	printf '#!/bin/sh\necho "Pike %s"\n' "$version" > "${version_path}/build/pike"
	chmod +x "${version_path}/build/pike"
	ln -sf "${version_path}/build/pike" "${version_path}/bin/pike"
}

cleanup_fake() {
	local version="$1"
	rm -rf "${PVM_DIR}/versions/${version}"
}

test_ls_empty() {
	local result
	result="$(pvm_command_ls)"
	run_test
	if [ -z "$(printf '%s' "$result" | grep -v "^pvm:")" ]; then
		pass
	else
		fail "ls should show nothing when no versions installed"
	fi
}

test_ls_marks_current() {
	setup_fake "8.0.1116"
	setup_fake "8.0.1732"

	pvm_command_use "8.0.1116" >/dev/null

	local result
	result="$(pvm_command_ls)"
	run_test
	if printf '%s' "$result" | grep "8.0.1116" | grep -q "(current)"; then
		pass
	else
		fail "ls should mark 8.0.1116 as current, got: $result"
	fi

	pvm_command_deactivate >/dev/null 2>&1 || true
	cleanup_fake "8.0.1116"
	cleanup_fake "8.0.1732"
}

test_ls_marks_default() {
	setup_fake "8.0.1116"
	pvm_set_alias "default" "8.0.1116"

	local result
	result="$(pvm_command_ls)"
	run_test
	if printf '%s' "$result" | grep "8.0.1116" | grep -q "default"; then
		pass
	else
		fail "ls should mark default version, got: $result"
	fi

	pvm_remove_alias "default"
	cleanup_fake "8.0.1116"
}

test_ls_pattern_no_match() {
	setup_fake "8.0.1116"

	local result
	result="$(pvm_command_ls "9.9")"
	run_test
	if ! printf '%s' "$result" | grep -q "8.0.1116"; then
		pass
	else
		fail "ls with pattern '9.9' should not match 8.0.1116"
	fi

	cleanup_fake "8.0.1116"
}

test_ls_empty
test_ls_marks_current
test_ls_marks_default
test_ls_pattern_no_match
