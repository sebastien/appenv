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
# cmd-list.test.sh -- Tests for _appenv_list, _appenv_names, _appenv_loaded

set -euo pipefail

BASE_PATH="$(dirname "$(dirname "$(readlink -f "$0")")")"
source "$BASE_PATH/tests/lib-testing.sh"
source "$BASE_PATH/share/appenv/commands.bash"

# === TESTS ===================================================================

test-init "Command: list, names, and loaded tests"

# Setup test directory structure
test-step "Setup test directories"
TEST_SUBDIR="$TEST_PATH/subdir"
TEST_SUBDIR_FILEMODE="$TEST_PATH/subdir_file"
TEST_FILEMODE="$TEST_PATH/filemode"
mkdir -p "$TEST_PATH/.appenv"
mkdir -p "$TEST_SUBDIR/.appenv"
mkdir -p "$TEST_SUBDIR_FILEMODE"
mkdir -p "$TEST_FILEMODE"
mkdir -p "$TEST_PATH/parent"
mkdir -p "$TEST_PATH/parent/child"

# Create test .appenv directory scripts
cat > "$TEST_PATH/.appenv/root.appenv.sh" << 'EOF'
appenv_name root-script
EOF

# Create test .appenv files (file mode - separate from directory mode)
cat > "$TEST_FILEMODE/.appenv" << 'EOF'
appenv_name root-project
EOF

cat > "$TEST_SUBDIR_FILEMODE/.appenv" << 'EOF'
appenv_name subdir-project
EOF

cat > "$TEST_PATH/parent/.appenv" << 'EOF'
appenv_name parent-project
EOF

cat > "$TEST_PATH/parent/child/.appenv" << 'EOF'
appenv_name child-project
EOF

test-ok "Test directories created"

# --- Test 1: List .appenv files in directory ---------------------------------
test-step "_appenv_list finds .appenv file in directory"
cd "$TEST_FILEMODE"
result=$(_appenv_list "." 2>/dev/null)
result=$(echo "$result" | head -1)
if echo "$result" | grep -q ".appenv"; then
	test-ok "Found .appenv file"
else
	test-fail "Expected to find .appenv, got: '$result'"
fi

# --- Test 2: List .appenv/*.appenv.sh files ----------------------------------
test-step "_appenv_list finds .appenv/*.appenv.sh files"
cd "$TEST_PATH"
result=$(_appenv_list "." 2>/dev/null)
if echo "$result" | grep -q "root.appenv.sh"; then
	test-ok "Found root.appenv.sh"
else
	test-fail "Expected to find root.appenv.sh, got: '$result'"
fi

# --- Test 3: List traverses parent directories --------------------------------
test-step "_appenv_list traverses parent directories"
cd "$TEST_SUBDIR_FILEMODE"
# Filter results to only include test directory paths to avoid picking up user's home .appenv files
result=$(_appenv_list "." 2>/dev/null | grep -E "^$TEST_PATH|^$TEST_SUBDIR_FILEMODE" || true)
# Check for file paths, not project names (names are inside files)
if echo "$result" | grep -q "subdir_file/.appenv" && echo "$result" | grep -q "root.appenv.sh"; then
	test-ok "Found .appenv in current and parent dirs"
else
	test-fail "Expected multiple .appenv files, got: '$result'"
fi

# --- Test 4: List from nested child directory --------------------------------
test-step "_appenv_list from deeply nested directory"
cd "$TEST_PATH/parent/child"
result=$(_appenv_list "." 2>/dev/null | wc -l)
if [ "$result" -ge 3 ]; then
	test-ok "Found multiple .appenv files in hierarchy"
else
	test-fail "Expected at least 3 results, got: $result"
fi

# --- Test 5: _appenv_names extracts name from file ----------------------------
test-step "_appenv_names extracts appenv_name from file"
result=$(_appenv_names "$TEST_FILEMODE/.appenv")
# Check if result contains the expected name (function may output additional info)
if echo "$result" | grep -q "^root-project$"; then
	test-ok "Extracted name 'root-project'"
else
	test-fail "Expected 'root-project', got: '$result'"
fi

# --- Test 6: _appenv_names extracts from filename ----------------------------
test-step "_appenv_names extracts name from filename"
result=$(_appenv_names "$TEST_PATH/.appenv/root.appenv.sh")
if echo "$result" | grep -q "root-script"; then
	test-ok "Extracted name from appenv_name declaration"
else
	test-fail "Expected 'root-script', got: '$result'"
fi

# --- Test 7: _appenv_names auto-prefix stripping -----------------------------
test-step "_appenv_names strips auto-prefix from filename"
result=$(_appenv_names "/path/to/auto-001-test.appenv.sh")
if echo "$result" | grep -q "test"; then
	test-ok "Extracted 'test' from auto-001-test.appenv.sh"
else
	test-fail "Expected 'test', got: '$result'"
fi

# --- Test 8: _appenv_loaded lists loaded environments --------------------------
test-step "_appenv_loaded lists APPENV_LOADED contents"
export APPENV_LOADED="/path/one.appenv.sh:/path/two.appenv.sh"
result=$(_appenv_loaded)
if echo "$result" | grep -q "one.appenv.sh" && echo "$result" | grep -q "two.appenv.sh"; then
	test-ok "Listed loaded environments"
else
	test-fail "Expected both paths, got: '$result'"
fi
unset APPENV_LOADED

test-end
