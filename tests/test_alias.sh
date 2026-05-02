#!/usr/bin/env bash
# test_alias.sh — Tests for alias management
# Sourced by run_tests.sh

test_set_and_get_alias() {
	pvm_set_alias "test-alias" "8.0.1116"
	local result
	result="$(pvm_get_alias "test-alias")"
	run_test
	if [ "$result" = "8.0.1116" ]; then
		pass
	else
		fail "alias 'test-alias' should be '8.0.1116', got '$result'"
	fi
	# Cleanup
	pvm_remove_alias "test-alias"
}

test_get_nonexistent_alias() {
	local result
	if result="$(pvm_get_alias "nonexistent" 2>/dev/null)"; then
		run_test
		fail "get_alias should fail for nonexistent alias"
	else
		run_test
		pass
	fi
}

test_remove_alias() {
	pvm_set_alias "to-remove" "8.0.1732"
	pvm_remove_alias "to-remove"
	local result
	if result="$(pvm_get_alias "to-remove" 2>/dev/null)"; then
		run_test
		fail "alias should not exist after removal"
	else
		run_test
		pass
	fi
}

test_default_alias() {
	pvm_set_alias "default" "8.0.1116"
	local result
	result="$(pvm_get_alias "default")"
	run_test
	if [ "$result" = "8.0.1116" ]; then
		pass
	else
		fail "default alias should be '8.0.1116', got '$result'"
	fi
	pvm_remove_alias "default"
}

test_list_aliases() {
	pvm_set_alias "alias-one" "8.0.1116"
	pvm_set_alias "alias-two" "8.0.1732"
	local result
	result="$(pvm_list_aliases)"
	run_test
	if printf '%s' "$result" | grep -q "alias-one" && \
	   printf '%s' "$result" | grep -q "alias-two"; then
		pass
	else
		fail "list_aliases should contain 'alias-one' and 'alias-two', got: $result"
	fi
	pvm_remove_alias "alias-one"
	pvm_remove_alias "alias-two"
}

test_set_and_get_alias
test_get_nonexistent_alias
test_remove_alias
test_default_alias
test_list_aliases
