#!/usr/bin/env bash
#
#    __     _____   _____      __    ___   __  __
#  /'__`\  /\ '__`\/\ '__`\  /'__`\/' _ `\/\ \/\ \
# /\ \L\.\_\ \ \L\ \ \ \L\ \/\  __//\ \/\ \ \ \_/ |
# \ \__/.\_\\ \ ,__/\ \ ,__/\ \____\ \_\ \_\ \___/
#  \/__/\/_/ \ \ \/  \ \ \/  \/____/\/_/\/_/\/__/
#             \ \_\   \ \_\
#              \/_/    \/_/
#
# -----------------------------------------------------------------------------
# api-declare.test.sh -- Tests for appenv_declare function

set -euo pipefail

BASE_PATH="$(dirname "$(dirname "$(readlink -f "$0")")")"
source "$BASE_PATH/tests/lib-testing.sh"
source "$BASE_PATH/share/appenv/api.bash"

# === TESTS ===================================================================

test-init "API: appenv_declare tests"

# --- Test 1: Basic declaration -----------------------------------------------
test-step "appenv_declare sets variable with default value"
export APPENV_FILE="/test/file.appenv.sh"
unset TEST_VAR_1 2>/dev/null || true
appenv_declare TEST_VAR_1
if [ "${TEST_VAR_1:-}" = "/test/file.appenv.sh" ]; then
	test-ok "Variable set to APPENV_FILE by default"
else
	test-fail "Expected APPENV_FILE value, got: '${TEST_VAR_1:-}'"
fi
unset TEST_VAR_1

# --- Test 2: Declaration with custom value -----------------------------------
test-step "appenv_declare sets variable with custom value"
unset TEST_VAR_2 2>/dev/null || true
appenv_declare TEST_VAR_2 "/custom/path"
if [ "${TEST_VAR_2:-}" = "/custom/path" ]; then
	test-ok "Variable set to custom value"
else
	test-fail "Expected '/custom/path', got: '${TEST_VAR_2:-}'"
fi
unset TEST_VAR_2

# --- Test 3: Duplicate prevention --------------------------------------------
test-step "appenv_declare exits when variable already set to same value"
export TEST_VAR_3="/existing/path"
export APPENV_FILE="/existing/path"
# Run in subshell to capture exit code without exiting parent
if (
	set +e
	appenv_declare TEST_VAR_3 "/existing/path" 2>/dev/null
); then
	test-fail "Should have exited on duplicate"
else
	test-ok "Script exits on duplicate"
fi
unset TEST_VAR_3

# --- Test 4: Name added to APPENV_STATUS --------------------------------------
test-step "appenv_declare adds name to APPENV_STATUS"
unset TEST_VAR_4 2>/dev/null || true
unset APPENV_STATUS 2>/dev/null || true
export APPENV_FILE="/test/file.appenv.sh"
appenv_declare TEST_VAR_4
if echo "${APPENV_STATUS:-}" | grep -q "TEST_VAR_4"; then
	test-ok "Name added to APPENV_STATUS"
else
	test-fail "Name not found in APPENV_STATUS: '${APPENV_STATUS:-}'"
fi
unset TEST_VAR_4
unset APPENV_STATUS

# --- Test 5: Hyphen to underscore conversion ----------------------------------
test-step "appenv_declare converts hyphens to underscores"
unset TEST_VAR_5 2>/dev/null || true
export APPENV_FILE="/test/file.appenv.sh"
appenv_declare TEST-VAR-5 "/path"
if [ "${TEST_VAR_5:-}" = "/path" ]; then
	test-ok "Hyphens converted to underscores"
else
	test-fail "Expected TEST_VAR_5 to be set, got: '${TEST_VAR_5:-}'"
fi
unset TEST_VAR_5

# --- Test 6: Different value updates variable ---------------------------------
test-step "appenv_declare updates when value differs"
export TEST_VAR_6="/old/path"
export APPENV_FILE="/test/file.appenv.sh"
appenv_declare TEST_VAR_6 "/new/path"
if [ "${TEST_VAR_6:-}" = "/new/path" ]; then
	test-ok "Variable updated to new value"
else
	test-fail "Expected '/new/path', got: '${TEST_VAR_6:-}'"
fi
unset TEST_VAR_6

test-end
