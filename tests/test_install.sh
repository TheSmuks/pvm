#!/usr/bin/env bash
# test_install.sh — Tests for install/use/current commands
# Sourced by run_tests.sh

# Create a fake Pike installation for testing
setup_fake_installation() {
	local version="$1"
	local version_path="${PVM_DIR}/versions/${version}"
	mkdir -p "${version_path}/bin"
	mkdir -p "${version_path}/build"
	# Create a fake pike binary
	printf '#!/bin/sh\necho "Pike %s"\n' "$version" > "${version_path}/build/pike"
	chmod +x "${version_path}/build/pike"
	ln -sf "${version_path}/build/pike" "${version_path}/bin/pike"
}

cleanup_fake_installation() {
	local version="$1"
	rm -rf "${PVM_DIR}/versions/${version}"
}

test_is_version_installed() {
	setup_fake_installation "8.0.1116"
	run_test
	if pvm_is_version_installed "8.0.1116"; then
		pass
	else
		fail "8.0.1116 should be detected as installed"
	fi
	cleanup_fake_installation "8.0.1116"
}

test_is_version_not_installed() {
	run_test
	if ! pvm_is_version_installed "9.9.9999"; then
		pass
	else
		fail "9.9.9999 should not be detected as installed"
	fi
}

test_version_path() {
	local result
	result="$(pvm_version_path "8.0.1116")"
	run_test
	if [ "$result" = "${PVM_DIR}/versions/8.0.1116" ]; then
		pass
	else
		fail "version_path should be '${PVM_DIR}/versions/8.0.1116', got '$result'"
	fi
}

test_version_bin_path() {
	local result
	result="$(pvm_version_bin_path "8.0.1116")"
	run_test
	if [ "$result" = "${PVM_DIR}/versions/8.0.1116/bin" ]; then
		pass
	else
		fail "version_bin_path should be '${PVM_DIR}/versions/8.0.1116/bin', got '$result'"
	fi
}

test_use_switches_version() {
	setup_fake_installation "8.0.1116"
	setup_fake_installation "8.0.1732"

	pvm_command_use "8.0.1116" >/dev/null
	local result
	result="$(pvm_command_current)"
	run_test
	if [ "$result" = "8.0.1116" ]; then
		pass
	else
		fail "current should be '8.0.1116', got '$result'"
	fi

	pvm_command_use "8.0.1732" >/dev/null
	result="$(pvm_command_current)"
	run_test
	if [ "$result" = "8.0.1732" ]; then
		pass
	else
		fail "current should be '8.0.1732' after switch, got '$result'"
	fi

	# Cleanup PATH
	pvm_command_deactivate >/dev/null 2>&1 || true
	cleanup_fake_installation "8.0.1116"
	cleanup_fake_installation "8.0.1732"
}

test_use_not_installed() {
	run_test
	if pvm_command_use "9.9.9999" 2>/dev/null; then
		fail "use should fail for non-installed version"
	else
		pass
	fi
}

test_current_no_active() {
	# Make sure no version is active
	unset PVM_BIN PVM_PIKE
	run_test
	if pvm_command_current 2>/dev/null; then
		fail "current should fail when no version is active"
	else
		pass
	fi
}

test_ls_lists_versions() {
	setup_fake_installation "8.0.1116"
	setup_fake_installation "8.0.1732"

	local result
	result="$(pvm_command_ls)"
	run_test
	if printf '%s' "$result" | grep -q "8.0.1116" && \
	   printf '%s' "$result" | grep -q "8.0.1732"; then
		pass
	else
		fail "ls should list both versions, got: $result"
	fi

	cleanup_fake_installation "8.0.1116"
	cleanup_fake_installation "8.0.1732"
}

test_ls_with_pattern() {
	setup_fake_installation "8.0.1116"
	setup_fake_installation "8.0.1732"

	local result
	result="$(pvm_command_ls "1732")"
	run_test
	if printf '%s' "$result" | grep -q "8.0.1732" && \
	   ! printf '%s' "$result" | grep -q "8.0.1116"; then
		pass
	else
		fail "ls with pattern '1732' should only show 8.0.1732, got: $result"
	fi

	cleanup_fake_installation "8.0.1116"
	cleanup_fake_installation "8.0.1732"
}

test_uninstall() {
	setup_fake_installation "8.0.1116"

	# Make sure not current
	unset PVM_BIN PVM_PIKE

	pvm_command_uninstall "8.0.1116" >/dev/null
	run_test
	if ! pvm_is_version_installed "8.0.1116"; then
		pass
	else
		fail "version should not exist after uninstall"
	fi
}

test_uninstall_current_fails() {
	setup_fake_installation "8.0.1116"
	pvm_command_use "8.0.1116" >/dev/null

	run_test
	if pvm_command_uninstall "8.0.1116" 2>/dev/null; then
		fail "uninstall should fail for current version"
	else
		pass
	fi

	pvm_command_deactivate >/dev/null 2>&1 || true
	cleanup_fake_installation "8.0.1116"
}

test_is_version_installed
test_is_version_not_installed
test_version_path
test_version_bin_path
test_use_switches_version
test_use_not_installed
test_current_no_active
test_ls_lists_versions
test_ls_with_pattern
test_uninstall
test_uninstall_current_fails
