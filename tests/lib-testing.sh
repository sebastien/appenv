#!/usr/bin/env bash

# --
# Primitives for testing

set -euo pipefail

# We'll be changing path on a regular basis, so we keep track of it
FILENAME="$(basename "$0")"
ORIGINAL_PATH="$PWD"
ORIGINAL_TMPDIR="${TMPDIR:-/tmp}"
BASE_PATH="$(dirname "$(dirname "$(readlink -f "$0")")")"

# Variable: TEST_NAME
# Keeps track of the current test
TEST_NAME=""

# Variable: TEST_STEP_NAME
# Keeps track of the current test step
TEST_STEP_NAME=""

# Variable: TEST_PATH
# Keeps track of the current test path
TEST_PATH=""

# Variable: TEST_ERRORS[]
# Keeps track of the errors for the current test
declare -a TEST_ERRORS=()

# Variable: TEST_OKS[]
# Keeps track of the oks for the current test
declare -a TEST_OKS=()

# Variable: TEST_LOG[]
# Keeps track of the steps and their status
declare -a TEST_LOG=()

# Variable: TEST_CLEAN[]
# Keeps track of the files to clean
declare -a TEST_CLEAN=()

TEST_CLEAN+=("")

# Variable: TEST_COUNT
# Counts the number of tests started
TEST_COUNT=${TEST_COUNT:-0}
TEST_STEP_COUNT=${TEST_STEP_COUNT:-0}

# Variable: TEST_CURRENT
# Current number for the test
TEST_CURRENT=""
TEST_CURRENT_STEP=""

# Variable(internal): TEST_EXPECT_FAILURE
# Set when the test is expected to fail
TEST_EXPECT_FAILURE=""

# --
# ## Color library
if [ -z "${NOCOLOR:-}" ] && [ -n "${TERM:-}" ] && tput setaf 1 &>/dev/null; then
	CYAN="$(tput setaf 33)"
	BLUE_DK="$(tput setaf 27)"
	BLUE="$(tput setaf 33)"
	BLUE_LT="$(tput setaf 117)"
	GREEN="$(tput setaf 34)"
	YELLOW="$(tput setaf 220)"
	GRAY="$(tput setaf 153)"
	GOLD="$(tput setaf 214)"
	GOLD_DK="$(tput setaf 208)"
	PURPLE_DK="$(tput setaf 55)"
	PURPLE="$(tput setaf 92)"
	PURPLE_LT="$(tput setaf 163)"
	RED="$(tput setaf 124)"
	ORANGE="$(tput setaf 202)"
	BOLD="$(tput bold)"
	DIM="$(tput dim)"
	REVERSE="$(tput rev)"
	RESET="$(tput sgr0)"
else
	CYAN=""
	BLUE_DK=""
	BLUE=""
	BLUE_LT=""
	GREEN=""
	YELLOW=""
	GRAY=""
	GOLD=""
	GOLD_DK=""
	PURPLE_DK=""
	PURPLE=""
	PURPLE_LT=""
	RED=""
	ORANGE=""
	BOLD=""
	DIM=""
	REVERSE=""
	RESET=""
fi
export CYAN BLUE_DK
export BLUE
export BLUE_LT
export GREEN
export GRAY
export YELLOW
export GOLD
export GOLD_DK
export PURPLE_DK
export PURPLE
export PURPLE_LT
export RED
export ORANGE
export BOLD
export DIM
export REVERSE
export RESET

# Test data is not public, so we restrict the umask.
umask 0077

# -----------------------------------------------------------------------------
#
# TESTS LIFECYCLE
#
# -----------------------------------------------------------------------------

function test-init {
	test-start "$@"
	# We ensure the exit is called
	trap test-end EXIT INT TERM ERR
}

# --
# Starts the test, running the test in a new temporary
# directory set to `TEST_PATH`
#
# ```
# test-start "My test"
# ```
function test-start {
	if [ -n "$TEST_PATH" ]; then
		test-end
	fi
	((TEST_COUNT += 1))
	TEST_CURRENT=$TEST_COUNT
	TEST_CURRENT_STEP=""
	TEST_PATH="$(realpath "$(mktemp -d -p "$ORIGINAL_PATH" -t tmp.testing.XXX)")"
	TMPDIR="$TEST_PATH"
	export TMPDIR
	TEST_NAME="${1:-$TEST_NAME}"
	TEST_NAME="${TEST_NAME:-$FILENAME}"
	test_log "${BLUE}>>> ${YELLOW}${BOLD}${TEST_NAME} ${RESET}${BLUE}${DIM}in '${TEST_PATH}'${RESET}"
	if [ -z "$TEST_PATH" ] || [ ! -d "$TEST_PATH" ]; then
		test_log_error "Path empty or does not exists: '$TEST_PATH'"
		test_cleanup
		return 1
	fi
	cd "$TEST_PATH"
	export TEST_COUNT
}

# Function: test-end
# Ends the current test (see `TEST_PATH`) and outputs a report
function test-end {
	local res=0
	TEST_CURRENT_STEP=""
	local sn=${#TEST_OKS[@]}
	local en=${#TEST_ERRORS[@]}
	local tn=$((sn + en))

	if [ -n "$TEST_CURRENT" ] && [ $tn -gt 0 ]; then
		COLOR="${BLUE}"
		if [ "$en" -gt 0 ]; then
			if [ "$sn" -eq 0 ]; then
				COLOR="$RED"
			else
				COLOR="$ORANGE"
			fi
		fi
		test_log "${COLOR}LOG   (${BOLD}$tn${RESET}${COLOR}=${GREEN}$sn${COLOR}+${RED}$en${COLOR}) ${TEST_LOG[*]}${RESET}"
		# Detail of errors
		if [ "$en" != 0 ]; then
			for err in "${TEST_ERRORS[@]}"; do test_log "${RED}FAIL  ${BLUE}${BOLD}$err"; done
		fi
		# Test result
		if [ "$tn" == 0 ]; then
			# Empty test
			test_log "${GREEN}${BOLD}EPASS 100% (0/0)${RESET}"
			res=0
		elif [ ${#TEST_ERRORS[@]} -eq 0 ]; then
			# 100% sucesss
			test_log "${GREEN}${BOLD}EOK${RESET}${GREEN}  $((100 * sn / tn))% ($sn/$tn) succeeded${RESET}"
			res=0
		elif [ "$sn" == 0 ]; then
			# 100% failed
			test_log "${RED}${BOLD}EFAIL${RESET}${RED} $((100 * en / tn))% ($en/$tn) failed${RESET}"
			res=2
		else
			# Partial fail
			test_log "${RED}${BOLD}EFAIL${RESET}${RED} $((100 * en / tn))% ($en/$tn) failed${RESET}"
			res=1
		fi
		if [ "$res" == 0 ]; then
			test_log "${GREEN}<<< ${BOLD}${DIM}${TEST_NAME}"
		else
			test_log "${RED}<<< ${BOLD}${DIM}${TEST_NAME}"
		fi
	fi
	# We always do a cleanup
	test_cleanup
	# And restore
	unset 'TEST_ERRORS[@]'
	unset 'TEST_LOG[@]'
	TEST_CURRENT=""
	TEST_NAME=""
	TEST_PATH=""
	TMPDIR="$ORIGINAL_TMPDIR"
	export TMPDIR
	return $res
}

# Function(internal): test_cleanup
# Peforms a cleanup
function test_cleanup {
	if [ -e "$TEST_PATH" ]; then
		chmod -R u+w "$TEST_PATH" 2>/dev/null || true
		rm -rf "$TEST_PATH"
	fi
	for path in "${TEST_CLEAN[@]}"; do
		if [ -z "$path" ]; then
			continue
		elif [ -d "$path" ]; then
			chmod -R u+w "$path" 2>/dev/null || true
			rm -rf "$path"
		elif [ -e "$path" ]; then
			chmod u+w "$path" 2>/dev/null || true
			unlink "$path"
		fi
	done
	# We've cleaned everything
	unset 'TEST_CLEAN[@]'
}

# -----------------------------------------------------------------------------
#
# TEST STRUCTURE
#
# -----------------------------------------------------------------------------

function test-case {
	test-step "$@"
}

function test-step {
	((TEST_STEP_COUNT += 1))
	TEST_CURRENT_STEP=$TEST_STEP_COUNT
	test_log "${BLUE}--→ ${BOLD}$*${RESET}"
	TEST_STEP_NAME="$*"
	# FIXME: Not sure about that
	# if [ "$TEST_CURRENT" != "$TEST_COUNT" ]; then
	# 	if [ "$TEST_CURRENT_ERRORS" != "${#TEST_ERRORS[*]}" ]; then
	# 		local errcount=${#TEST_ERRORS[*]}
	# 		test_log_error "FAIL $((errcount - TEST_CURRENT_ERRORS)) error(s)"
	# 	fi
	# fi
	# TEST_CURRENT_ERRORS="${#TEST_ERRORS[*]}"
}

# -----------------------------------------------------------------------------
#
# TEST ACTIONS
#
# -----------------------------------------------------------------------------

# Function: test-cmd COMMAND…
# Runs the command and fails the test if the command fails.
function test-cmd {
	if ! "$@"; then
		test-fail "Subcommand failed [$?]: $(test_fmt_line "$*")"
		return 1
	else
		return 0
	fi
}

# --
# Function: test-run PREFIX COMMAND…
# Runs the given command as a test
function test-run {
	local exit_code
	local prefix="$1"
	shift
	TEST_CURRENT_STEP=$TEST_STEP_COUNT
	TEST_STEP_NAME="$*"
	((TEST_STEP_COUNT += 1))
	test_log "${BLUE}=== ${YELLOW}${BOLD}$* ${RESET}${BLUE}${DIM}in '${ORIGINAL_PATH}'${RESET}"
	env -C "$ORIGINAL_PATH" "$SHELL" "$@" 2> >(sed "s/^/${RESET}${prefix} . ${GRAY}/" >&2) > >(sed "s/^/${RESET}${prefix} ! ${ORANGE}/")
	return $?
}

function test_log_run {
	local prefix
	prefix="$(test_prefix)$1"
	shift
	"$@" 2> >(sed "s/^/${RED}${prefix} /" >&2) > >(sed "s/^/${BLUE}${prefix} /")
	return $?
}

function test-ok {
	if [ -n "$*" ]; then
		test_log_success "$*"
	fi
	TEST_LOG+=("${GREEN}✓")
	TEST_OKS+=("$(test_step_id)")
}

function test-fail {
	test_log_error "FAIL $*"
	TEST_LOG+=("${RED}×")
	TEST_ERRORS+=("[$(test_step_id)] ×←- ${TEST_STEP_NAME} $*")
}

# Function: test-fatal
# Fatal error, aborts everything
function test-fatal {
	if [ -z "$TEST_EXPECT_FAILURE" ]; then
		test_log_error "Fatal failure $*"
		TEST_LOG+=("${RED}×")
		TEST_ERRORS+=("[$(test_step_id)] ×←- ${TEST_STEP_NAME} $*")
		test-end
	fi
}

# Function: test-abort
# Aborts the entire test, triggering a test end
function test-abort {
	if [ -n "${1:-}" ]; then
		test_log_error "ABRT $*"
	fi
	TEST_LOG+=("${ORANGE}☇")
	TEST_ERRORS+=("[$(test_step_id)] ☇←- ${TEST_STEP_NAME} $*")
	test-end
}

# -----------------------------------------------------------------------------
#
# TEST PREDICATES
#
# -----------------------------------------------------------------------------

function test-expect {
	if [ "$1" != "$2" ]; then
		test-fail "Expected output differ" "${3:-}"
		test-diff "$1" "$2"
	else
		test-ok "${3:-}"
	fi
}

function test-expect-different {
	if [ "$1" == "$2" ]; then
		test-fail "Expected output identical" "$(test_fmt_line "$1")"
	else
		test-ok "${3:-}"
	fi
}

# Function: test-expect-success COMMAND…
function test-expect-success {
	local exit_code=$?
	if [ -n "$*" ]; then
		"$@"
		exit_code=$?
	fi
	if [ $exit_code != 0 ]; then
		test-fail "Subcommand was expected to succeed but failed [$exit_code] $(test_fmt_line "$*")"
		return $exit_code
	else
		test-ok
		return 0
	fi
}

function test-expect-failure {
	TEST_EXPECT_FAILURE="yes"
	# Save current errexit state
	local has_errexit=false
	if [[ $- == *e* ]]; then
		has_errexit=true
		set +e # Disable errexit
	fi

	test_log "${BLUE}>>> Expected to fail:${DIM} [$(test_fmt_line "$*")]"
	test_log_run "${ORANGE}${DIM}>>>" "$@"
	local res=$?

	if [[ "$has_errexit" == true ]]; then
		set -e
	fi

	TEST_EXPECT_FAILURE=""
	# Check if test failed as expected
	if [[ $res -ne 0 ]]; then
		test-ok
		return 0
	else
		test-fail "Command was expected to fail got [$res]:${DIM} [$(test_fmt_line "$*")"
		return 1
	fi
}

function test-path {
	if [ ! -e "$BASE_PATH/.deps/run" ]; then mkdir -p "$BASE_PATH/.deps/run"; fi
	TEST_PATH="$(mktemp -d -p "$BASE_PATH/.deps/run" "$TEST_NAME.test.XXXXX")"
	export TEST_PATH
	mkdir -p "$TEST_PATH"
	cd "$ORIGINAL_PATH"
	echo -n "$TEST_PATH"
}

function test-relpath {
	realpath --relative-to="$PWD" "$1"
}

function test-substring { # STRING STRING…
	local str="$1"
	shift
	for expr in "$@"; do
		if ! grep -qF -- "$expr" <(echo "$str"); then
			test-fail "'$str' does not contain: '$expr'"
			return 1
		fi
	done
	return 0

}

function test-contains { # PATH STRING…
	local path="$1"
	shift
	if [ ! -e "$path" ]; then
		test-fail "Path $(test-relpath "$path") does not exist"
		return 1
	else
		for expr in "$@"; do
			if ! grep -q "$expr" "$path"; then
				test-fail "Path $(test-relpath "$path") does not contain: $expr"
				return 1
			fi
		done
		return 0
	fi
}

function test-exist {
	if [ ! -e "$1" ]; then
		test-fail "Path does not exists: $1"
		return 1
	elif [ -n "${2:-}" ]; then
		test-ok "$2: $(test-relpath "$1")"
	else
		test-ok "$(test-relpath "$1") exists"
	fi
	return 0
}

function test-path-noempty {
	for path in "$@"; do
		if [ ! -f "$path" ]; then
			test-fail "path does not exists: $path"
		elif [ ! -s "$path" ]; then
			test-fail "path is empty: $path"
		else
			test-ok
		fi
	done
}

function test-empty {
	local value="$1"
	local failure="${2:-}"
	if [ -n "$value" ]; then
		test-fail "$failure"
	else
		test-ok
	fi
}

function test-noempty {
	local value="$1"
	local message="${2:-}"
	if [ -z "$value" ]; then
		test-fail "$message"
	else
		test-ok "$message"
	fi
}
function test-data {
	local data_path="$BASE_PATH/tests/data/$1"
	if [ -n "$1" ] && [ -e "$data_path" ]; then
		echo -n "$data_path"
	elif [ -z "$1" ]; then
		test-fail "'test-data FILENAME' is missing FILENAME argument"
		exit 1
	else
		test-fail "Could not find test data: path=$data_path"
		exit 1
	fi
}

# -----------------------------------------------------------------------------
#
# TEST OUTPUT
#
# -----------------------------------------------------------------------------

function test-diff {
	if [ "$1" != "$2" ]; then
		local a
		local b
		a=$(mktemp -p "$TEST_PATH" var.XXX)
		b=$(mktemp -p "$TEST_PATH" var.XXX)
		echo "$1" >"$a"
		echo "$2" >"$b"
		test_log "${ORANGE}>>> Retrieved/Expected"
		test_log "${ORANGE}A:[${RESET}$1${ORANGE}] $(openssl sha256 "$a" | cut -d' ' -f2)"
		test_log "${ORANGE}B:[${RESET}$2${ORANGE}] $(openssl sha256 "$b" | cut -d' ' -f2)"
		test_log_run "${ORANGE}>>>" diff -u "$a" "$b"
		test_log "<<<${RESET}"
		unlink "$a"
		unlink "$b"
	fi
}

function test-output {
	echo ">>>" >&2
	echo "$@" >&2
	echo "<<<" >&2
}

function test-info {
	echo " → $*" >&2
}

# Function(internal): test_fmt_line STR MAXLEN
function test_fmt_line {
	local str="$1"
	str=$(echo "$str" | tr '\n' '\\n')
	local max_len="${2:-80}"
	if [ ${#str} -gt "$max_len" ]; then
		echo "${str:0:$max_len}…"
	else
		echo "$str"
	fi
}

# -----------------------------------------------------------------------------
#
# TEST ATTRIBUTES
#
# -----------------------------------------------------------------------------

function test_id {
	printf "%03d" "$TEST_CURRENT"
}

function test_step_id {
	printf "%03d.%03d" "$TEST_CURRENT" "$TEST_CURRENT_STEP"
}

function test_prefix {
	local prefix
	if [ -z "${TEST_CURRENT}" ]; then
		prefix="-"
	elif [ -z "${TEST_CURRENT_STEP}" ]; then
		prefix=$(test_id)
	else
		prefix=$(test_step_id)
	fi
	echo -n "${BLUE}${DIM}[${TEST_NAME:-$FILENAME}:${BOLD}${RESET}${BLUE}$prefix${RESET}${DIM}${BLUE}] ${RESET}"

}

function test_nocolor {
	# Use printf to generate control chars for BSD sed compatibility
	# Remove ANSI escape sequences and control characters
	LC_ALL=C sed -e 's/\x1b\[[0-9;]*[a-zA-Z]//g' -e 's/\x1b(B//g' -e 's/[[:cntrl:]]//g'

}
# -----------------------------------------------------------------------------
#
# TEST LOGGING
#
# -----------------------------------------------------------------------------

function test_log {
	echo "${RESET}$(test_prefix)$*${RESET}" >&2
}

function test_log_separator {
	test_log "${DIM}―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――"
}

function test_log_message {
	test_log "${BLUE}... ${DIM}$*"
}

function test_log_output {
	test_log "${GRAY} =  ${DIM}$*"
}

function test_log_success {
	test_log "${GREEN} ✓  ${RESET}${DIM}$*"
}

function test_log_error {
	test_log "${RED}!!! $*"
}

function test_signal_err {
	test_log "${RED}-!- Unmanaged error [$?] $*"
}

function test_signal_exit {
	test-end
}

# Function: test-tempfile [SUFFIX] [PREFIX]
# Creates a temporary file that will be cleaned up when the test ends.
# Returns the path to the temporary file.
function test-tempfile() {
	local prefix="${2:-}"
	local suffix="${1:-}"
	local parent="${TEST_PATH:-/tmp}"
	local tmp
	if [[ -n "${prefix}" ]] && [[ -n "${suffix}" ]]; then
		if ! tmp=$(mktemp -p "$parent" -t "${prefix}.XXXXXX${suffix}"); then
			test-abort "Failed to create temporary file"
			exit 1
		fi
	elif [[ -n "${prefix}" ]]; then
		if ! tmp=$(mktemp -p "$parent" -t "${prefix}.XXXXXX"); then
			test-abort "Failed to create temporary file"
			exit 1
		fi
	else
		if ! tmp=$(mktemp -p "$parent"); then
			test-abort "Failed to create temporary file"
			exit 1
		fi
	fi
	TEST_CLEAN+=("${tmp}")
	echo "${tmp}"
}

trap test_signal_err ERR
trap test_signal_exit EXIT INT TERM

# EOF
