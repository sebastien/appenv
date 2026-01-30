#!/usr/bin/env bash
#
#    __     _____   _____      __    ___   __  __
#  /'__`\  /\ '__`\/\ '__`\  /'__`\/' _ `\/\ \/\ \
# /\ \L\.\_\ \ \L\ \ \ \L\ \/\  __//\ \/\ \ \ \_/ |
# \ \__/.\_\\ \ ,__/\ \ ,__/\ \____\ \_\ \_\ \___/
#  \/__/\/_/ \ \ \/  \ \ \/  \/____/\/_/\/_/\/__/
#             \ \_\   \_\_
#              \/_/    \/_/
#
# -----------------------------------------------------------------------------
# api-module.test.sh -- Tests for appenv_module, appenv_name, appenv_post

set -euo pipefail

BASE_PATH="$(dirname "$(dirname "$(readlink -f "$0")")")"
source "$BASE_PATH/tests/lib-testing.sh"
source "$BASE_PATH/share/appenv/api.bash"

# === TESTS ===================================================================

test-init "API: Module, naming and post-command tests"

# --- Test 1: appenv_name adds to APPENV_STATUS -------------------------------
test-step "appenv_name adds name to APPENV_STATUS"
unset APPENV_STATUS 2>/dev/null || true
appenv_name "myenv"
if echo "${APPENV_STATUS:-}" | grep -q "myenv"; then
	test-ok "Name added to APPENV_STATUS"
else
	test-fail "Name not in APPENV_STATUS: '${APPENV_STATUS:-}'"
fi
unset APPENV_STATUS

# --- Test 2: appenv_name multiple calls --------------------------------------
test-step "appenv_name handles multiple environment names"
unset APPENV_STATUS 2>/dev/null || true
appenv_name "env1"
appenv_name "env2"
appenv_name "env3"
if [ "${APPENV_STATUS:-}" = "env1:env2:env3" ]; then
	test-ok "Multiple names added with colons"
else
	test-fail "Expected 'env1:env2:env3', got: '${APPENV_STATUS:-}'"
fi
unset APPENV_STATUS

# --- Test 3: appenv_module basic --------------------------------------------
test-step "appenv_module declares module with name"
unset MY_MODULE 2>/dev/null || true
unset APPENV_STATUS 2>/dev/null || true
export APPENV_FILE="/test/module.appenv.sh"
appenv_module "my-module"
if [ "${MY_MODULE:-}" = "/test/module.appenv.sh" ] && echo "${APPENV_STATUS:-}" | grep -q "my-module"; then
	test-ok "Module declared and name added to status"
else
	test-fail "MY_MODULE='${MY_MODULE:-}', APPENV_STATUS='${APPENV_STATUS:-}'"
fi
unset MY_MODULE
unset APPENV_STATUS

# --- Test 4: appenv_module with custom value --------------------------------
test-step "appenv_module with custom value"
unset MY_CUSTOM 2>/dev/null || true
unset APPENV_STATUS 2>/dev/null || true
appenv_module "my-custom" "/custom/value"
if [ "${MY_CUSTOM:-}" = "/custom/value" ] && echo "${APPENV_STATUS:-}" | grep -q "my-custom"; then
	test-ok "Module with custom value declared"
else
	test-fail "MY_CUSTOM='${MY_CUSTOM:-}', APPENV_STATUS='${APPENV_STATUS:-}'"
fi
unset MY_CUSTOM
unset APPENV_STATUS

# --- Test 5: appenv_module hyphen to uppercase conversion -------------------
test-step "appenv_module converts hyphens to underscores and uppercases"
unset MY_TEST_MODULE 2>/dev/null || true
appenv_module "my-test-module"
if [ -n "${MY_TEST_MODULE:-}" ]; then
	test-ok "Name converted to MY_TEST_MODULE"
else
	test-fail "Expected MY_TEST_MODULE to be set"
fi
unset MY_TEST_MODULE
unset APPENV_STATUS

# --- Test 6: appenv_module duplicate prevention ------------------------------
test-step "appenv_module exits on duplicate module"
export MY_DUP_MODULE="existing"
export APPENV_FILE="existing"
if (
	set +e
	appenv_module "my-dup-module" 2>/dev/null
); then
	test-fail "Should have exited on duplicate"
else
	test-ok "Module exits on duplicate"
fi
unset MY_DUP_MODULE

# --- Test 7: appenv_post sets command ----------------------------------------
test-step "appenv_post sets APPENV_POST variable"
unset APPENV_POST 2>/dev/null || true
appenv_post "echo hello"
if [ "${APPENV_POST:-}" = "echo hello" ]; then
	test-ok "Post command set"
else
	test-fail "Expected 'echo hello', got: '${APPENV_POST:-}'"
fi
unset APPENV_POST

# --- Test 8: appenv_post multiple commands -----------------------------------
test-step "appenv_post accumulates multiple commands"
unset APPENV_POST 2>/dev/null || true
appenv_post "echo first"
appenv_post "echo second"
if echo "${APPENV_POST:-}" | grep -q "echo first" && echo "${APPENV_POST:-}" | grep -q "echo second"; then
	test-ok "Multiple commands accumulated with semicolons"
else
	test-fail "Commands not accumulated: '${APPENV_POST:-}'"
fi
unset APPENV_POST

# --- Test 9: appenv_log output -----------------------------------------------
test-step "appenv_log produces output"
output=$(appenv_log "Test message" 2>&1)
if echo "$output" | grep -q "Test message"; then
	test-ok "Log message output"
else
	test-fail "Log message not found in output: '$output'"
fi

# --- Test 10: appenv_error output -------------------------------------------
test-step "appenv_error produces output to stderr"
output=$(appenv_error "Error message" 2>&1)
if echo "$output" | grep -q "Error message"; then
	test-ok "Error message output to stderr"
else
	test-fail "Error message not found: '$output'"
fi

test-end
