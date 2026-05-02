#!/usr/bin/env bash
# test_use.sh — Tests for use/current/which/deactivate/exec/run
# Sourced by run_tests.sh

# Create a fake Pike installation
setup_fake() {
	local version="$1"
	local version_path="${PVM_DIR}/versions/${version}"
	mkdir -p "${version_path}/bin"
	mkdir -p "${version_path}/build"
	mkdir -p "${version_path}/build/lib/modules"
	mkdir -p "${version_path}/build/include"
	printf '#!/bin/sh\necho "Pike %s"\n' "$version" > "${version_path}/build/pike"
	chmod +x "${version_path}/build/pike"
	ln -sf "${version_path}/build/pike" "${version_path}/bin/pike"
	# Create a fake master.pike
	printf '// fake master for %s\n' "$version" > "${version_path}/master.pike"
	# Create a fake module so we can test module path resolution
	printf '//! @decl void foo()\n' > "${version_path}/build/lib/modules/Foo.pmod"
}

cleanup_fake() {
	local version="$1"
	rm -rf "${PVM_DIR}/versions/${version}"
}

test_which_current() {
	setup_fake "8.0.1116"
	pvm_command_use "8.0.1116" >/dev/null

	local result
	result="$(pvm_command_which)"
	run_test
	if [ "$result" = "${PVM_DIR}/versions/8.0.1116/bin/pike" ]; then
		pass
	else
		fail "which should return pike binary path, got '$result'"
	fi

	pvm_command_deactivate >/dev/null 2>&1 || true
	cleanup_fake "8.0.1116"
}

test_which_specific_version() {
	setup_fake "8.0.1732"

	local result
	result="$(pvm_command_which "8.0.1732")"
	run_test
	if [ "$result" = "${PVM_DIR}/versions/8.0.1732/bin/pike" ]; then
		pass
	else
		fail "which 8.0.1732 should return its path, got '$result'"
	fi

	cleanup_fake "8.0.1732"
}

test_deactivate() {
	setup_fake "8.0.1116"
	pvm_command_use "8.0.1116" >/dev/null

	pvm_command_deactivate >/dev/null
	run_test
	if [ -z "${PVM_BIN:-}" ]; then
		pass
	else
		fail "PVM_BIN should be unset after deactivate"
	fi

	cleanup_fake "8.0.1116"
}

test_deactivate_when_not_active() {
	unset PVM_BIN PVM_PIKE
	run_test
	if pvm_command_deactivate 2>/dev/null; then
		fail "deactivate should fail when not active"
	else
		pass
	fi
}

test_exec_command() {
	setup_fake "8.0.1116"

	local result
	result="$(pvm_command_exec "8.0.1116" pike)"
	run_test
	if printf '%s' "$result" | grep -q "Pike 8.0.1116"; then
		pass
	else
		fail "exec should run pike with correct version, got '$result'"
	fi

	cleanup_fake "8.0.1116"
}

test_run_command() {
	setup_fake "8.0.1732"

	# pvm run uses exec, which replaces the process — test with a non-blocking command
	# We can't easily test exec in unit tests, so just verify the setup is correct
	run_test
	local pike_bin="${PVM_DIR}/versions/8.0.1732/bin/pike"
	if [ -x "$pike_bin" ]; then
		pass
	else
		fail "pike binary should be executable for pvm run"
	fi

	cleanup_fake "8.0.1732"
}

test_path_manipulation() {
	setup_fake "8.0.1116"
	setup_fake "8.0.1732"

	pvm_command_use "8.0.1116" >/dev/null
	run_test
	case ":${PATH}:" in
		*":${PVM_DIR}/versions/8.0.1116/bin:"*)
			pass
			;;
		*)
			fail "PATH should contain 8.0.1116/bin"
			;;
	esac

	pvm_command_use "8.0.1732" >/dev/null
	run_test
	case ":${PATH}:" in
		*":${PVM_DIR}/versions/8.0.1732/bin:"*)
			pass
			;;
		*)
			fail "PATH should contain 8.0.1732/bin after switch"
			;;
	esac
	# Verify old version is not in PATH
	case ":${PATH}:" in
		*":${PVM_DIR}/versions/8.0.1116/bin:"*)
			fail "PATH should NOT contain 8.0.1116/bin after switching to 8.0.1732"
			;;
		*)
			run_test
			pass
			;;
	esac

	pvm_command_deactivate >/dev/null 2>&1 || true
	cleanup_fake "8.0.1116"
	cleanup_fake "8.0.1732"
}

# ---- Pike environment variable tests ----

test_use_sets_pike_module_path() {
	setup_fake "8.0.1116"
	pvm_command_use "8.0.1116" >/dev/null

	run_test
	local expected="${PVM_DIR}/versions/8.0.1116/build/lib/modules"
	if [ "${PIKE_MODULE_PATH%"$expected"*}" != "$PIKE_MODULE_PATH" ]; then
		pass
	else
		fail "PIKE_MODULE_PATH should contain $expected, got '$PIKE_MODULE_PATH'"
	fi

	pvm_command_deactivate >/dev/null 2>&1 || true
	cleanup_fake "8.0.1116"
}

test_use_sets_pike_master() {
	setup_fake "8.0.1116"
	pvm_command_use "8.0.1116" >/dev/null

	run_test
	local expected="${PVM_DIR}/versions/8.0.1116/master.pike"
	if [ "${PIKE_MASTER:-}" = "$expected" ]; then
		pass
	else
		fail "PIKE_MASTER should be $expected, got '${PIKE_MASTER:-}'"
	fi

	pvm_command_deactivate >/dev/null 2>&1 || true
	cleanup_fake "8.0.1116"
}

test_use_sets_pvm_pike_home() {
	setup_fake "8.0.1116"
	pvm_command_use "8.0.1116" >/dev/null

	run_test
	local expected_home="${PVM_DIR}/versions/8.0.1116/build"
	if [ "${PVM_PIKE_HOME:-}" = "$expected_home" ]; then
		pass
	else
		fail "PVM_PIKE_HOME should be $expected_home, got '${PVM_PIKE_HOME:-}'"
	fi

	run_test
	if [ "${PVM_PIKE_VERSION:-}" = "8.0.1116" ]; then
		pass
	else
		fail "PVM_PIKE_VERSION should be 8.0.1116, got '${PVM_PIKE_VERSION:-}'"
	fi

	pvm_command_deactivate >/dev/null 2>&1 || true
	cleanup_fake "8.0.1116"
}

test_deactivate_clears_pike_env() {
	setup_fake "8.0.1116"
	pvm_command_use "8.0.1116" >/dev/null
	pvm_command_deactivate >/dev/null

	run_test
	if [ -z "${PIKE_MODULE_PATH:-}" ]; then
		pass
	else
		fail "PIKE_MODULE_PATH should be unset after deactivate, got '$PIKE_MODULE_PATH'"
	fi

	run_test
	if [ -z "${PIKE_MASTER:-}" ]; then
		pass
	else
		fail "PIKE_MASTER should be unset after deactivate, got '${PIKE_MASTER:-}'"
	fi

	run_test
	if [ -z "${PVM_PIKE_HOME:-}" ]; then
		pass
	else
		fail "PVM_PIKE_HOME should be unset after deactivate, got '${PVM_PIKE_HOME:-}'"
	fi

	run_test
	if [ -z "${PVM_PIKE_VERSION:-}" ]; then
		pass
	else
		fail "PVM_PIKE_VERSION should be unset after deactivate, got '${PVM_PIKE_VERSION:-}'"
	fi

	cleanup_fake "8.0.1116"
}

test_switch_version_updates_pike_env() {
	setup_fake "8.0.1116"
	setup_fake "8.0.1732"

	pvm_command_use "8.0.1116" >/dev/null
	pvm_command_use "8.0.1732" >/dev/null

	run_test
	local expected="${PVM_DIR}/versions/8.0.1732/build/lib/modules"
	if [ "${PIKE_MODULE_PATH%"$expected"*}" != "$PIKE_MODULE_PATH" ]; then
		pass
	else
		fail "PIKE_MODULE_PATH should contain $expected after switch, got '$PIKE_MODULE_PATH'"
	fi

	run_test
	if [ "${PVM_PIKE_VERSION:-}" = "8.0.1732" ]; then
		pass
	else
		fail "PVM_PIKE_VERSION should be 8.0.1732 after switch, got '${PVM_PIKE_VERSION:-}'"
	fi

	# Also verify old version path is NOT in PIKE_MODULE_PATH
	run_test
	local old_path="${PVM_DIR}/versions/8.0.1116/build/lib/modules"
	case ":${PIKE_MODULE_PATH}:" in
		*":${old_path}:"*)
			fail "PIKE_MODULE_PATH should NOT contain old version $old_path after switch"
			;;
		*)
			pass
			;;
	esac

	pvm_command_deactivate >/dev/null 2>&1 || true
	cleanup_fake "8.0.1116"
	cleanup_fake "8.0.1732"
}

test_existing_module_path_preserved() {
	# Set a pre-existing PIKE_MODULE_PATH before activating pvm
	export PIKE_MODULE_PATH="/my/custom/modules:/other/path"

	setup_fake "8.0.1116"
	pvm_command_use "8.0.1116" >/dev/null

	run_test
	# After pvm use, our version should be prepended, but custom paths preserved
	local expected="${PVM_DIR}/versions/8.0.1116/build/lib/modules"
	if [ "${PIKE_MODULE_PATH%"$expected"*}" != "$PIKE_MODULE_PATH" ]; then
		pass
	else
		fail "PIKE_MODULE_PATH should contain $expected, got '$PIKE_MODULE_PATH'"
	fi

	run_test
	case ":${PIKE_MODULE_PATH}:" in
		*":/my/custom/modules:"*)
			pass
			;;
		*)
			fail "PIKE_MODULE_PATH should preserve /my/custom/modules, got '$PIKE_MODULE_PATH'"
			;;
	esac

	pvm_command_deactivate >/dev/null 2>&1 || true
	unset PIKE_MODULE_PATH
	cleanup_fake "8.0.1116"
}

test_which_current
test_which_specific_version
test_deactivate
test_deactivate_when_not_active
test_exec_command
test_run_command
test_path_manipulation
test_use_sets_pike_module_path
test_use_sets_pike_master
test_use_sets_pvm_pike_home
test_deactivate_clears_pike_env
test_switch_version_updates_pike_env
test_existing_module_path_preserved
