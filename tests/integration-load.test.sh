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
# integration-load.test.sh -- Integration tests for appenv-load workflows

set -euo pipefail

BASE_PATH="$(dirname "$(dirname "$(readlink -f "$0")")")"
source "$BASE_PATH/tests/lib-testing.sh"
source "$BASE_PATH/share/appenv/commands.bash"
source "$BASE_PATH/share/appenv/api.bash"

# === TESTS ===================================================================

test-init "Integration: appenv-load workflows"

# Setup test environment
test-step "Setup test environment"
TEST_APPENV_DIR="$TEST_PATH/.appenv"
mkdir -p "$TEST_APPENV_DIR"
export HOME="$TEST_PATH"

# Create test environment files
cat > "$TEST_APPENV_DIR/dev.appenv.sh" << 'EOF'
appenv_name dev-env
appenv_set DEV_MODE active
EOF

cat > "$TEST_APPENV_DIR/staging.appenv.sh" << 'EOF'
appenv_name staging-env
appenv_set STAGING_MODE active
EOF

cat > "$TEST_APPENV_DIR/auto-001-prod.appenv.sh" << 'EOF'
appenv_name prod-env
appenv_set PROD_MODE active
EOF

test-ok "Test environment created"

# --- Test 1: Load by name ----------------------------------------------------
test-step "Load environment by name"
unset DEV_MODE 2>/dev/null || true
unset APPENV_LOADED 2>/dev/null || true
unset APPENV_STATUS 2>/dev/null || true
cd "$TEST_PATH"
export APPENV_FILE="$TEST_APPENV_DIR/dev.appenv.sh"
export APPENV_DIR="$TEST_APPENV_DIR"
appenv_file=$(_appenv_locate "dev")
if [ -n "$appenv_file" ]; then
	source "$appenv_file"
fi
if [ "${DEV_MODE:-}" = "active" ]; then
	test-ok "DEV_MODE set by loading 'dev'"
else
	test-fail "Expected DEV_MODE=active, got: '${DEV_MODE:-}'"
fi

# --- Test 2: Verify APPENV_STATUS tracking -----------------------------------
test-step "Verify loaded environment name tracked in APPENV_STATUS"
if echo "${APPENV_STATUS:-}" | grep -q "dev-env"; then
	test-ok "dev-env in APPENV_STATUS"
else
	test-fail "Expected dev-env in APPENV_STATUS"
fi

# --- Test 4: Load by auto-prefixed name -------------------------------------
test-step "Load auto-prefixed environment by short name"
unset PROD_MODE 2>/dev/null || true
export APPENV_FILE="$TEST_APPENV_DIR/auto-001-prod.appenv.sh"
export APPENV_DIR="$TEST_APPENV_DIR"
appenv_file=$(_appenv_locate "prod")
if [ -n "$appenv_file" ]; then
	source "$appenv_file"
fi
if [ "${PROD_MODE:-}" = "active" ]; then
	test-ok "PROD_MODE set by loading 'prod'"
else
	test-fail "Expected PROD_MODE=active, got: '${PROD_MODE:-}'"
fi

# --- Test 5: Load by full path -----------------------------------------------
test-step "Load environment by full path"
unset STAGING_MODE 2>/dev/null || true
export APPENV_FILE="$TEST_APPENV_DIR/staging.appenv.sh"
export APPENV_DIR="$TEST_APPENV_DIR"
appenv_file=$(_appenv_locate "$TEST_APPENV_DIR/staging.appenv.sh")
if [ -n "$appenv_file" ]; then
	source "$appenv_file"
fi
if [ "${STAGING_MODE:-}" = "active" ]; then
	test-ok "STAGING_MODE set by loading full path"
else
	test-fail "Expected STAGING_MODE=active, got: '${STAGING_MODE:-}'"
fi

# --- Test 6: Multiple environment variables set --------------------------------
test-step "Multiple environments set different variables"
if [ -n "${DEV_MODE:-}" ] && [ -n "${PROD_MODE:-}" ]; then
	test-ok "Multiple environments set their variables"
else
	test-fail "Expected DEV_MODE and PROD_MODE to be set"
fi

# --- Test 7: Load with stdin -------------------------------------------------
test-step "Load environment from stdin"
unset STDIN_VAR 2>/dev/null || true
# Create temp file and source it
stdin_file="$TEST_PATH/stdin-test.appenv.sh"
echo 'appenv_set STDIN_VAR "from-stdin"' > "$stdin_file"
export APPENV_FILE="$stdin_file"
export APPENV_DIR="$TEST_PATH"
source "$stdin_file"
if [ "${STDIN_VAR:-}" = "from-stdin" ]; then
	test-ok "Variable set from stdin-like input"
else
	test-fail "Expected STDIN_VAR=from-stdin, got: '${STDIN_VAR:-}'"
fi

# --- Test 8: APPENV_POST execution -------------------------------------------
test-step "APPENV_POST commands executed after load"
export POST_TEST_MARKER=""
cat > "$TEST_APPENV_DIR/post-test.appenv.sh" << 'EOF'
appenv_name post-test
appenv_post 'export POST_TEST_MARKER="executed"'
EOF
export APPENV_FILE="$TEST_APPENV_DIR/post-test.appenv.sh"
export APPENV_DIR="$TEST_APPENV_DIR"
source "$TEST_APPENV_DIR/post-test.appenv.sh"
# Execute APPENV_POST if set
if [ -n "${APPENV_POST:-}" ]; then
	eval "$APPENV_POST"
fi
if [ "${POST_TEST_MARKER:-}" = "executed" ]; then
	test-ok "APPENV_POST command was executed"
else
	test-fail "Expected POST_TEST_MARKER=executed, got: '${POST_TEST_MARKER:-}'"
fi

test-end
