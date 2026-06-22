#!/usr/bin/env bash
#
#    __     _____   _____      __    ___   __  __
#  /'__`\  /\ '__`\/\ '__`\  /'__`\/' _ `\/\ \/\ \
# /\ \L\.\_\ \ \L\ \ \ \L\ \/\  __//\ \/\ \ \ \_/ |
# \ \__/\.\\ \ ,__/\ \ ,__/\ \____\\ \_\ \_\ \___/
#  \/__/\/_/ \ \ \/  \ \ \/  \/____/\/_/\/_/\/__/
#             \ \_\   \ \_\
#              \/_/    \/_/
#
# -----------------------------------------------------------------------------
# cmd-reload.test.sh -- Tests for appenv-load reload behavior

set -euo pipefail

BASE_PATH="$(dirname "$(dirname "$(readlink -f "$0")")")"
source "$BASE_PATH/tests/lib-testing.sh"
source "$BASE_PATH/bin/appenv.bash"

# === TESTS ===================================================================

test-init "Command: reload tests"

function write_appenv {
	local file_path=${1:-}
	local mode=${2:-}
	local prefix=${3:-}
	cat > "$file_path" << EOF
appenv_name reload-env
appenv_set RELOAD_MODE "$mode"
appenv_prepend RELOAD_PATH "$prefix"
EOF
}

test-step "Setup test environment file"
TEST_APPENV_DIR="$TEST_PATH/.appenv"
mkdir -p "$TEST_APPENV_DIR"
APP_FILE="$TEST_APPENV_DIR/reload.appenv.sh"
export HOME="$TEST_PATH"
test-ok "Test environment ready"

# --- Test 1: Reload unchanged file reapplies environment ----------------------
test-step "Repeated load reapplies unchanged file"
unset RELOAD_MODE 2>/dev/null || true
unset RELOAD_PATH 2>/dev/null || true
unset APPENV_LOADED 2>/dev/null || true
unset APPENV_STATUS 2>/dev/null || true
export RELOAD_PATH="/original/path"
write_appenv "$APP_FILE" "first" "/v1/path"
appenv-load "$APP_FILE"
sha_var="APPENV_SHA_$(_appenv_file_key "$APP_FILE")"
first_sha="${!sha_var:-}"
export RELOAD_PATH="/ambient/changed"
appenv-load "$APP_FILE"
loaded_count=$(echo "${APPENV_LOADED:-}" | tr ':' '\n' | grep -Fc "$APP_FILE")
status_count=$(echo "${APPENV_STATUS:-}" | tr ':' '\n' | grep -Fc "reload-env")
if [ "${RELOAD_MODE:-}" = "first" ] \
	&& [ "${RELOAD_PATH:-}" = "/v1/path:/ambient/changed" ] \
	&& [ "$loaded_count" = "1" ] \
	&& [ "$status_count" = "1" ] \
	&& [ "${!sha_var:-}" = "$first_sha" ]; then
	test-ok "Unchanged file was unloaded and reapplied"
else
	test-fail "Expected unchanged reload reapply, got RELOAD_MODE='${RELOAD_MODE:-}' RELOAD_PATH='${RELOAD_PATH:-}' APPENV_LOADED='${APPENV_LOADED:-}' APPENV_STATUS='${APPENV_STATUS:-}'"
fi

# --- Test 2: Changed file unloads old state before reloading ------------------
test-step "Changed file unloads previous state before reload"
write_appenv "$APP_FILE" "second" "/v2/path"
appenv-load "$APP_FILE"
loaded_count=$(echo "${APPENV_LOADED:-}" | tr ':' '\n' | grep -Fc "$APP_FILE")
current_sha=$(_appenv_file_sha "$APP_FILE")
if [ "${RELOAD_MODE:-}" = "second" ] \
	&& [ "${RELOAD_PATH:-}" = "/v2/path:/ambient/changed" ] \
	&& [ "$loaded_count" = "1" ] \
	&& [ "${!sha_var:-}" = "$current_sha" ] \
	&& ! echo "${RELOAD_PATH:-}" | grep -Fq "/v1/path"; then
	test-ok "Changed file was unloaded then reloaded"
else
	test-fail "Expected changed reload, got RELOAD_MODE='${RELOAD_MODE:-}' RELOAD_PATH='${RELOAD_PATH:-}' APPENV_LOADED='${APPENV_LOADED:-}' SHA='${!sha_var:-}'"
fi

# --- Test 3: Unload clears stored SHA metadata --------------------------------
test-step "Unload clears SHA metadata"
_appenv_unload "$APP_FILE" 2>/dev/null
if [ -z "${RELOAD_MODE:-}" ] \
	&& [ "${RELOAD_PATH:-}" = "/ambient/changed" ] \
	&& [ -z "${APPENV_LOADED:-}" ] \
	&& [ -z "${!sha_var:-}" ]; then
	test-ok "Unload cleared file metadata and restored env"
else
	test-fail "Expected unload cleanup, got RELOAD_MODE='${RELOAD_MODE:-}' RELOAD_PATH='${RELOAD_PATH:-}' APPENV_LOADED='${APPENV_LOADED:-}' SHA='${!sha_var:-}'"
fi

test-end
