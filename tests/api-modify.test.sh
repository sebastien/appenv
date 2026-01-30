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
# api-modify.test.sh -- Tests for append/prepend/remove/set/clear functions

set -euo pipefail

BASE_PATH="$(dirname "$(dirname "$(readlink -f "$0")")")"
source "$BASE_PATH/tests/lib-testing.sh"
source "$BASE_PATH/share/appenv/api.bash"

# === TESTS ===================================================================

test-init "API: Environment variable modification tests"

# --- Test 1: appenv_append basic ---------------------------------------------
test-step "appenv_append adds value to empty variable"
unset TEST_APPEND
export APPENV_FILE="/test/file.appenv.sh"
appenv_append TEST_APPEND "/first/path"
if [ "${TEST_APPEND:-}" = "/first/path" ]; then
	test-ok "Value added to empty variable"
else
	test-fail "Expected '/first/path', got: '${TEST_APPEND:-}'"
fi
unset TEST_APPEND

# --- Test 2: appenv_append with existing value ------------------------------
test-step "appenv_append adds value with colon separator"
export TEST_APPEND="/existing/path"
appenv_append TEST_APPEND "/new/path"
if [ "${TEST_APPEND:-}" = "/existing/path:/new/path" ]; then
	test-ok "Value appended with colon separator"
else
	test-fail "Expected '/existing/path:/new/path', got: '${TEST_APPEND:-}'"
fi
unset TEST_APPEND

# --- Test 3: appenv_append prevents duplicates ------------------------------
test-step "appenv_append prevents duplicate values"
export TEST_APPEND="/path/one:/path/two"
appenv_append TEST_APPEND "/path/one"
if [ "${TEST_APPEND:-}" = "/path/one:/path/two" ]; then
	test-ok "Duplicate value not added"
else
	test-fail "Value was duplicated: '${TEST_APPEND:-}'"
fi
unset TEST_APPEND

# --- Test 4: appenv_append with custom separator ----------------------------
test-step "appenv_append uses custom separator"
export TEST_APPEND="item1"
appenv_append TEST_APPEND "item2" ","
if [ "${TEST_APPEND:-}" = "item1,item2" ]; then
	test-ok "Custom separator used"
else
	test-fail "Expected 'item1,item2', got: '${TEST_APPEND:-}'"
fi
unset TEST_APPEND

# --- Test 5: appenv_prepend basic -------------------------------------------
test-step "appenv_prepends adds value to empty variable"
unset TEST_PREPEND
export APPENV_FILE="/test/file.appenv.sh"
appenv_prepend TEST_PREPEND "/first/path"
if [ "${TEST_PREPEND:-}" = "/first/path" ]; then
	test-ok "Value added to empty variable"
else
	test-fail "Expected '/first/path', got: '${TEST_PREPEND:-}'"
fi
unset TEST_PREPEND

# --- Test 6: appenv_prepend with existing value -------------------------------
test-step "appenv_prepend adds value at beginning"
export TEST_PREPEND="/existing/path"
appenv_prepend TEST_PREPEND "/new/path"
if [ "${TEST_PREPEND:-}" = "/new/path:/existing/path" ]; then
	test-ok "Value prepended with colon separator"
else
	test-fail "Expected '/new/path:/existing/path', got: '${TEST_PREPEND:-}'"
fi
unset TEST_PREPEND

# --- Test 7: appenv_prepend prevents duplicates -------------------------------
test-step "appenv_prepend prevents duplicate values"
export TEST_PREPEND="/path/one:/path/two"
appenv_prepend TEST_PREPEND "/path/one"
if [ "${TEST_PREPEND:-}" = "/path/one:/path/two" ]; then
	test-ok "Duplicate value not prepended"
else
	test-fail "Value was duplicated: '${TEST_PREPEND:-}'"
fi
unset TEST_PREPEND

# --- Test 8: appenv_set basic -----------------------------------------------
test-step "appenv_set sets variable value"
unset TEST_SET
export APPENV_FILE="/test/file.appenv.sh"
appenv_set TEST_SET "myvalue"
if [ "${TEST_SET:-}" = "myvalue" ]; then
	test-ok "Variable set correctly"
else
	test-fail "Expected 'myvalue', got: '${TEST_SET:-}'"
fi
unset TEST_SET

# --- Test 9: appenv_set overwrites existing ----------------------------------
test-step "appenv_set overwrites existing value"
export TEST_SET="oldvalue"
appenv_set TEST_SET "newvalue"
if [ "${TEST_SET:-}" = "newvalue" ]; then
	test-ok "Variable overwritten"
else
	test-fail "Expected 'newvalue', got: '${TEST_SET:-}'"
fi
unset TEST_SET

# --- Test 10: appenv_remove --------------------------------------------------
test-step "appenv_remove removes value from variable"
export TEST_REMOVE="/keep/this:/remove/this:/keep/that"
appenv_remove TEST_REMOVE "/remove/this"
if [ "${TEST_REMOVE:-}" = "/keep/this::/keep/that" ]; then
	test-ok "Value removed from middle"
else
	test-fail "Expected '/keep/this::/keep/that', got: '${TEST_REMOVE:-}'"
fi
unset TEST_REMOVE

# --- Test 11: appenv_remove no match -----------------------------------------
test-step "appenv_remove does nothing when value not found"
export TEST_REMOVE="/path/one:/path/two"
appenv_remove TEST_REMOVE "/not/found"
if [ "${TEST_REMOVE:-}" = "/path/one:/path/two" ]; then
	test-ok "Variable unchanged when value not found"
else
	test-fail "Variable was modified: '${TEST_REMOVE:-}'"
fi
unset TEST_REMOVE

# --- Test 12: appenv_clear ---------------------------------------------------
test-step "appenv_clear unsets variable value"
export TEST_CLEAR="somevalue"
appenv_clear TEST_CLEAR
if [ -z "${TEST_CLEAR:-}" ]; then
	test-ok "Variable cleared"
else
	test-fail "Expected empty, got: '${TEST_CLEAR:-}'"
fi

# --- Test 13: PATH manipulation (real-world use case) ------------------------
test-step "PATH manipulation with prepend and append"
export PATH="/usr/bin:/bin"
appenv_prepend PATH "/usr/local/bin"
appenv_append PATH "$HOME/.local/bin"
# Check that PATH starts with /usr/local/bin and ends with .local/bin
if [[ "$PATH" == /usr/local/bin:* ]] && [[ "$PATH" == *:$HOME/.local/bin ]]; then
	test-ok "PATH correctly modified"
else
	test-fail "PATH not as expected: '$PATH'"
fi

test-end
