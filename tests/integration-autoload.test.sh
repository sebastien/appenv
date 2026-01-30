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
# integration-autoload.test.sh -- Integration tests for appenv autoloading

set -euo pipefail

BASE_PATH="$(dirname "$(dirname "$(readlink -f "$0")")")"
source "$BASE_PATH/tests/lib-testing.sh"
source "$BASE_PATH/share/appenv/commands.bash"
source "$BASE_PATH/share/appenv/api.bash"

# === TESTS ===================================================================

test-init "Integration: appenv autoloading workflows"

# Setup test environment
test-step "Setup test environment"
export HOME="$TEST_PATH"

# Create project directory structure
mkdir -p "$TEST_PATH/project"
mkdir -p "$TEST_PATH/project/subdir"
mkdir -p "$TEST_PATH/other-project"

# Create .appenv files
cat > "$TEST_PATH/project/.appenv" << 'EOF'
appenv_name project-env
appenv_set PROJECT_ROOT "$APPENV_DIR"
EOF

cat > "$TEST_PATH/other-project/.appenv" << 'EOF'
appenv_name other-project-env
appenv_set OTHER_VAR "other-value"
EOF

test-ok "Test directories created"

# --- Test 1: Load local .appenv by locating it --------------------------
test-step "Load .appenv in current directory"
unset PROJECT_ROOT 2>/dev/null || true
unset APPENV_LOADED 2>/dev/null || true
unset APPENV_STATUS 2>/dev/null || true
cd "$TEST_PATH/project"
export APPENV_FILE="$TEST_PATH/project/.appenv"
export APPENV_DIR="$TEST_PATH/project"
appenv_file=$(_appenv_locate "")
if [ -n "$appenv_file" ]; then
	source "$appenv_file"
fi
if [ -n "${PROJECT_ROOT:-}" ]; then
	test-ok "PROJECT_ROOT set by loading .appenv"
else
	test-fail "Expected PROJECT_ROOT to be set"
fi

# --- Test 2: Check APPENV_STATUS tracking -------------------------------------
test-step "Verify APPENV_STATUS tracks environment names"
if echo "${APPENV_STATUS:-}" | grep -q "project-env"; then
	test-ok "project-env in APPENV_STATUS"
else
	test-fail "Expected project-env in APPENV_STATUS"
fi

# --- Test 4: Load by name from ~/.appenv directory --------------------------
test-step "Load environment by name from ~/.appenv"
mkdir -p "$TEST_PATH/.appenv"
cat > "$TEST_PATH/.appenv/home-env.appenv.sh" << 'EOF'
appenv_name home-env
appenv_set HOME_ENV_VAR "home-value"
EOF
unset HOME_ENV_VAR 2>/dev/null || true
export APPENV_LOADED=""
export APPENV_STATUS=""
cd "$TEST_PATH"
appenv_file=$(_appenv_locate "home-env")
if [ -n "$appenv_file" ]; then
	source "$appenv_file"
fi
if [ "${HOME_ENV_VAR:-}" = "home-value" ]; then
	test-ok "HOME_ENV_VAR set by loading 'home-env'"
else
	test-fail "Expected HOME_ENV_VAR=home-value, got: '${HOME_ENV_VAR:-}'"
fi

# --- Test 5: Different .appenv files in different directories ---------------
test-step "Load different .appenv files in different directories"
unset PROJECT_ROOT 2>/dev/null || true
unset OTHER_VAR 2>/dev/null || true
export APPENV_LOADED=""
export APPENV_STATUS=""
cd "$TEST_PATH/project"
project_file=$(_appenv_locate "")
[ -n "$project_file" ] && source "$project_file"
project_set="${PROJECT_ROOT:-}"
cd "$TEST_PATH/other-project"
other_file=$(_appenv_locate "")
[ -n "$other_file" ] && source "$other_file"
other_set="${OTHER_VAR:-}"
if [ -n "$project_set" ] && [ -n "$other_set" ]; then
	test-ok "Different .appenv files loaded in different directories"
else
	test-fail "Expected both environments to set variables"
fi

test-end
