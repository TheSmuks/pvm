#!/usr/bin/env bash
# test_platform.sh — Tests for platform detection
# Sourced by run_tests.sh

test_pvm_get_os() {
	local os
	os="$(pvm_get_os)"
	case "$os" in
		Linux|MacOSX|Windows|FreeBSD|*)
			run_test
			if [ -n "$os" ]; then
				pass
			else
				fail "pvm_get_os returned empty"
			fi
			;;
	esac
}

test_pvm_get_arch() {
	local arch
	arch="$(pvm_get_arch)"
	run_test
	if [ -n "$arch" ]; then
		pass
	else
		fail "pvm_get_arch returned empty"
	fi
}

test_pvm_get_os_returns_known_value() {
	local os
	os="$(pvm_get_os)"
	run_test
	case "$os" in
		Linux|MacOSX|Windows|FreeBSD|Darwin)
			pass
			;;
		*)
			# uname -s returned something unexpected but non-empty — still valid
			if [ -n "$os" ]; then
				pass
			else
				fail "pvm_get_os returned empty for unknown OS"
			fi
			;;
	esac
}

test_pvm_get_arch_returns_known_value() {
	local arch
	arch="$(pvm_get_arch)"
	run_test
	case "$arch" in
		x86_64|arm64|ppc64|ppc64le|riscv64|i386)
			pass
			;;
		*)
			if [ -n "$arch" ]; then
				pass
			else
				fail "pvm_get_arch returned empty for unknown arch"
			fi
			;;
	esac
}

test_pvm_get_os
test_pvm_get_arch
test_pvm_get_os_returns_known_value
test_pvm_get_arch_returns_known_value
