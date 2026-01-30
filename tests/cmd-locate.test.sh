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
# cmd-locate.test.sh -- Tests for _appenv_locate function

set -euo pipefail

BASE_PATH="$(dirname "$(dirname "$(readlink -f "$0")")")"
source "$BASE_PATH/tests/lib-testing.sh"
source "$BASE_PATH/share/appenv/commands.bash"

# === TESTS ===================================================================

test-init "Command: locate tests"

# Setup test directory structure
test-step "Setup test directories"
TEST_APPENV_DIR="$TEST_PATH/.appenv"
TEST_FILEMODE="$TEST_PATH/filemode"
mkdir -p "$TEST_APPENV_DIR"
mkdir -p "$TEST_FILEMODE"
mkdir -p "$TEST_PATH/project"

# Create test .appenv directory scripts
cat > "$TEST_APPENV_DIR/dev.appenv.sh" << 'EOF'
appenv_name dev-env
EOF

cat > "$TEST_APPENV_DIR/auto-001-prod.appenv.sh" << 'EOF'
appenv_name prod-env
EOF

# Create test .appenv file (file mode - separate from directory mode)
cat > "$TEST_FILEMODE/.appenv" << 'EOF'
appenv_name local-project
EOF

cat > "$TEST_PATH/project/.appenv" << 'EOF'
appenv_name nested-project
EOF

test-ok "Test directories created"

# --- Test 1: Locate .appenv in current directory ----------------------------
test-step "_appenv_locate finds .appenv in current directory"
cd "$TEST_FILEMODE"
result=$(_appenv_locate "")
if [ "$result" = ".appenv" ]; then
	test-ok "Found .appenv file"
else
	test-fail "Expected '.appenv', got: '$result'"
fi

# --- Test 2: Locate by file path --------------------------------------------
test-step "_appenv_locate returns file path as-is"
result=$(_appenv_locate "$TEST_APPENV_DIR/dev.appenv.sh")
if [ "$result" = "$TEST_APPENV_DIR/dev.appenv.sh" ]; then
	test-ok "File path returned as-is"
else
	test-fail "Expected '$TEST_APPENV_DIR/dev.appenv.sh', got: '$result'"
fi

# --- Test 3: Locate by directory with .appenv --------------------------------
test-step "_appenv_locate finds .appenv in given directory"
result=$(_appenv_locate "$TEST_PATH/project")
if [ "$result" = "$TEST_PATH/project/.appenv" ]; then
	test-ok "Found .appenv in directory"
else
	test-fail "Expected '$TEST_PATH/project/.appenv', got: '$result'"
fi

# --- Test 4: Locate by name in ~/.appenv -------------------------------------
test-step "_appenv_locate finds by name"
export HOME="$TEST_PATH"
result=$(_appenv_locate "dev")
if echo "$result" | grep -q "dev.appenv.sh"; then
	test-ok "Found by name 'dev'"
else
	test-fail "Expected to find dev.appenv.sh, got: '$result'"
fi

# --- Test 5: Locate auto-prefixed file ---------------------------------------
test-step "_appenv_locate resolves auto-prefixed names"
result=$(_appenv_locate "prod")
if echo "$result" | grep -q "auto-001-prod.appenv.sh"; then
	test-ok "Resolved auto-001-prod.appenv.sh from 'prod'"
else
	test-fail "Expected auto-prefixed file, got: '$result'"
fi

# --- Test 6: Locate by appenv_name in file -----------------------------------
test-step "_appenv_locate finds by appenv_name in file"
result=$(_appenv_locate "dev-env")
if echo "$result" | grep -q "dev.appenv.sh"; then
	test-ok "Found by appenv_name 'dev-env'"
else
	test-fail "Expected to find dev.appenv.sh, got: '$result'"
fi

# --- Test 7: Locate non-existent file ----------------------------------------
test-step "_appenv_locate handles non-existent files"
result=$(_appenv_locate "nonexistent" 2>&1)
if echo "$result" | grep -qi "cannot locate\|error"; then
	test-ok "Error reported for non-existent file"
else
	test-fail "Expected error, got: '$result'"
fi

# --- Test 8: Locate symlink --------------------------------------------------
test-step "_appenv_locate handles symlinks"
ln -sf "$TEST_APPENV_DIR/dev.appenv.sh" "$TEST_PATH/link.appenv.sh"
result=$(_appenv_locate "$TEST_PATH/link.appenv.sh")
if echo "$result" | grep -q "link.appenv.sh"; then
	test-ok "Symlink returned as-is"
else
	test-fail "Expected symlink path, got: '$result'"
fi

test-end
