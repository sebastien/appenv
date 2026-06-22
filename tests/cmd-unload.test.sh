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
# cmd-unload.test.sh -- Tests for _appenv_unload function

set -euo pipefail

BASE_PATH="$(dirname "$(dirname "$(readlink -f "$0")")")"
source "$BASE_PATH/tests/lib-testing.sh"
source "$BASE_PATH/share/appenv/commands.bash"
source "$BASE_PATH/share/appenv/api.bash"

# === TESTS ===================================================================

test-init "Command: unload tests"

# Setup test environment
test-step "Setup test environment files"
TEST_APPENV_DIR="$TEST_PATH/.appenv"
mkdir -p "$TEST_APPENV_DIR"

cat > "$TEST_APPENV_DIR/test.appenv.sh" << 'EOF'
appenv_name test-env
appenv_set TEST_VAR "test-value"
appenv_prepend TEST_PATH_VAR "/test/path"
EOF

cat > "$TEST_APPENV_DIR/test2.appenv.sh" << 'EOF'
appenv_name test2-env
appenv_set TEST2_VAR "test2-value"
EOF

test-ok "Test files created"

# --- Test 1: Unload restores SET values --------------------------------------
test-step "Unload restores SET variable values"
unset TEST_VAR 2>/dev/null || true
unset APPENV_LOADED 2>/dev/null || true
export APPENV_FILE="$TEST_APPENV_DIR/test.appenv.sh"
export APPENV_DIR="$TEST_APPENV_DIR"
source "$TEST_APPENV_DIR/test.appenv.sh"
export APPENV_LOADED="$TEST_APPENV_DIR/test.appenv.sh"
export APPENV_STATUS="test-env"
# Now unload
_appenv_unload "$TEST_APPENV_DIR/test.appenv.sh" 2>/dev/null
if [ -z "${TEST_VAR:-}" ]; then
	test-ok "SET variable was restored (unset)"
else
	test-fail "Expected TEST_VAR to be unset, got: '${TEST_VAR:-}'"
fi

# --- Test 2: Unload restores PREPEND values --------------------------------
test-step "Unload restores PREPEND variable values"
unset TEST_PATH_VAR 2>/dev/null || true
unset APPENV_LOADED 2>/dev/null || true
unset APPENV_BACKUP_* 2>/dev/null || true
export TEST_PATH_VAR="/original/path"
export APPENV_FILE="$TEST_APPENV_DIR/test.appenv.sh"
export APPENV_DIR="$TEST_APPENV_DIR"
source "$TEST_APPENV_DIR/test.appenv.sh"
export APPENV_LOADED="$TEST_APPENV_DIR/test.appenv.sh"
export APPENV_STATUS="test-env"
# Unload
_appenv_unload "$TEST_APPENV_DIR/test.appenv.sh" 2>/dev/null
if [ "${TEST_PATH_VAR:-}" = "/original/path" ]; then
	test-ok "PREPEND was reverted, original value restored"
else
	test-fail "Expected '/original/path', got: '${TEST_PATH_VAR:-}'"
fi

# --- Test 3: Unload removes from APPENV_LOADED ------------------------------
test-step "Unload removes from APPENV_LOADED"
unset TEST_VAR 2>/dev/null || true
unset TEST2_VAR 2>/dev/null || true
export APPENV_LOADED="$TEST_APPENV_DIR/test.appenv.sh:$TEST_APPENV_DIR/test2.appenv.sh"
export APPENV_STATUS="test-env:test2-env"
export APPENV_FILE="$TEST_APPENV_DIR/test.appenv.sh"
export APPENV_DIR="$TEST_APPENV_DIR"
# Create backup manually for test
file_hash=$( (echo "$TEST_APPENV_DIR/test.appenv.sh" | sha256sum | cut -d' ' -f1) | head -c16 ) || true
export APPENV_BACKUP_${file_hash}="U0V0OlRFU1RfVkFSOnRlc3QtdmFsdWU="
_appenv_unload "$TEST_APPENV_DIR/test.appenv.sh" 2>/dev/null
if ! echo "${APPENV_LOADED:-}" | grep -q "test.appenv.sh"; then
	test-ok "Unloaded file removed from APPENV_LOADED"
else
	test-fail "File still in APPENV_LOADED: '${APPENV_LOADED:-}'"
fi

# --- Test 4: Unload removes from APPENV_STATUS ------------------------------
test-step "Unload removes from APPENV_STATUS"
if ! echo "${APPENV_STATUS:-}" | grep -q "test-env"; then
	test-ok "Name removed from APPENV_STATUS"
else
	test-fail "Name still in APPENV_STATUS: '${APPENV_STATUS:-}'"
fi

# --- Test 5: Unload last loaded when no argument -----------------------------
test-step "Unload last loaded when no argument provided"
unset TEST_VAR 2>/dev/null || true
unset TEST2_VAR 2>/dev/null || true
unset APPENV_LOADED 2>/dev/null || true
unset APPENV_STATUS 2>/dev/null || true
export APPENV_FILE="$TEST_APPENV_DIR/test2.appenv.sh"
export APPENV_DIR="$TEST_APPENV_DIR"
source "$TEST_APPENV_DIR/test2.appenv.sh"
export APPENV_LOADED="$TEST_APPENV_DIR/test2.appenv.sh"
export APPENV_STATUS="test2-env"
file_hash=$( (echo "$TEST_APPENV_DIR/test2.appenv.sh" | sha256sum | cut -d' ' -f1) | head -c16 ) || true
export APPENV_BACKUP_${file_hash}="U0VUOlRFU1QyX1ZBUjo="
_appenv_unload "" 2>/dev/null
if [ -z "${TEST2_VAR:-}" ]; then
	test-ok "Last loaded environment was unloaded"
else
	test-fail "Expected TEST2_VAR to be unset, got: '${TEST2_VAR:-}'"
fi

# --- Test 6: Unload error when not loaded ------------------------------------
test-step "Unload reports error when environment not loaded"
result=$(_appenv_unload "nonexistent" 2>&1 || true)
if echo "$result" | grep -qi "cannot find\|error\|not loaded"; then
	test-ok "Error reported for not-loaded environment"
else
	test-fail "Expected error message, got: '$result'"
fi

# --- Test 7: Unload error when no backup -------------------------------------
test-step "Unload reports error when no backup exists"
unset TEST_VAR 2>/dev/null || true
export APPENV_LOADED="/fake/path.appenv.sh"
result=$(_appenv_unload "/fake/path.appenv.sh" 2>&1 || true)
if echo "$result" | grep -qi "no backup\|error"; then
	test-ok "Error reported for missing backup"
else
	test-fail "Expected error message, got: '$result'"
fi

test-end
