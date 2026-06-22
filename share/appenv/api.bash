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
# _appenv.api.bash -- Bash implementation fo the appenv environment API. The
# commands defined here are what people would use when writing their .appenv
# scripts.
#
# SEE: http://stackoverflow.com/questions/229551/string-contains-in-bash

# === VERSION =================================================================

APPENV_API="0.0.0"
APPENV_POST=""
APPENV_LIB=$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")
source "$APPENV_LIB"/commands.bash

# -----------------------------------------------------------------------------
#
# LOW-LEVEL API
#
# -----------------------------------------------------------------------------

# TODO: This is the user-facing API and should then be documented properly

function _appenv_log_op {
	local op=${1:-}
	local name=${2:-}
	local value=${3:-}
	local file_hash=$(_appenv_file_key "${APPENV_FILE:-}")
	local backup_var="APPENV_BACKUP_${file_hash}"

	local entry=$(echo -n "${op}:${name}:${value}" | base64 -w0)

	if [ -z "${!backup_var:-}" ]; then
		export "$backup_var"="${entry}"
	else
		export "$backup_var"="${!backup_var:-},${entry}"
	fi
}

function appenv_declare {
	local NAME=${1//[-]/_}
	local VALUE=${2:-}
	local CURRENT
	CURRENT=$(printenv "$1" || true)
	if [ -z "$VALUE" ]; then
		VALUE="${APPENV_FILE:-}"
	fi
	if [ "$VALUE" != "$CURRENT" ]; then
		export "${NAME}"="${VALUE}"
		appenv_name "$1"
		_appenv_log_op "DECLARE" "$NAME" "$CURRENT"
	else
		_appenv_log "appenv: ${YELLOW_BOLD}$NAME${YELLOW} is already declared"
		exit 1
	fi
}

function appenv_append {
	local NAME=${1:-}
	local VALUE=${2:-}
	local SEP=${3:-}
	if [ -z "$SEP" ]; then
		SEP=":"
	fi
	local CURRENT
	CURRENT=$(printenv "$1" || true)
	# "Compatible answer"
	if [ -z "$CURRENT" ]; then
		export "${NAME}"="${VALUE}"
		_appenv_log_op "APPEND" "$NAME" "$VALUE"
	elif [ -n "${CURRENT##*$VALUE*}" ]; then
		export "${NAME}=${CURRENT}${SEP}${VALUE}"
		_appenv_log_op "APPEND" "$NAME" "$VALUE"
	fi
}

function appenv_prepend {
	local NAME=${1:-}
	local VALUE=${2:-}
	local CURRENT
	CURRENT=$(printenv "$1" || true)
	if [ -z "$CURRENT" ]; then
		export "${NAME}"="${VALUE}"
		_appenv_log_op "PREPEND" "$NAME" "$VALUE"
	elif [ -n "${CURRENT##*$VALUE*}" ]; then
		export "${NAME}=${VALUE}:${CURRENT}"
		_appenv_log_op "PREPEND" "$NAME" "$VALUE"
	fi
}

function appenv_remove {
	local NAME=${1:-}
	local VALUE=${2:-}
	local CURRENT
	CURRENT=$(printenv "$1" || true)
	local UPDATED="${CURRENT//$VALUE/}"
	if [ "$UPDATED" != "$CURRENT" ]; then
		export "${NAME}"="${UPDATED}"
	fi
}

function appenv_set {
	local NAME=${1:-}
	local VALUE=${2:-}
	local PREVIOUS=$(printenv "$NAME" || true)
	export "${NAME}"="${VALUE}"
	_appenv_log_op "SET" "$NAME" "$PREVIOUS"
}

function appenv_clear {
	local target=${1:-}
	local PREVIOUS=$(printenv "$target" || true)
	export "$target"=
	_appenv_log_op "CLEAR" "$1" "$PREVIOUS"
}

function appenv_log {
	echo -e "${YELLOW}${*}${NC}"
}

function appenv_error {
	>&2 echo -e "${*}"
}

function appenv_name {
	appenv_append APPENV_STATUS "${1:-}"
}

function appenv_module {
	local NAME
	NAME=$(echo "${1:-}" | tr '-' '_' | tr '[:lower:]' '[:upper:]')
	appenv_name "$1"
	appenv_declare "$NAME" "${2:-}"
}

function appenv_load {
	_appenv_load "$1"
}

function appenv_post {
	appenv_append APPENV_POST "$*" ';'
}

# EOF
