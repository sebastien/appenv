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
# _appenv.bash -- Bash shell implementation of the appenv commands.
# This loads one or more bash-compatible scripts given as argument and
# propagates the changed made to the environnemnt back into
# the current Bash shell session.

# === REQUIREMENTS ===========================================================

if [ ! -z `which python` ]; then
	APPENV_PYTHON="python"
elif [ ! -z `which python3` ]; then
	APPENV_PYTHON="python3"
fi

if [ -z "$APPENV_PYTHON" ]; then
	echo 'appenv: No Python interpreter found, install python or set APPENV_PYTHON variable'
fi

# === GLOBALS =================================================================

APPENV_BASE=$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")
if [ -z "$APPENV_LIB" ]; then
	APPENV_LIB="$APPENV_BASE"/../share/appenv
fi
APPENV_SHELL=$(which bash 2> /dev/null)

# === API =====================================================================
# Sets the given environment variable to the given value

source "$APPENV_LIB/commands.bash"

# === OVERRIDES ===============================================================

function _appenv_set {
	NAME=$1
	VALUE=$2
	PREVIOUS=$2
	eval "export ${NAME}=\"${VALUE}\""
}

# === WRAPPERS ================================================================

function appenv-locate {
	_appenv_locate "$@"
}

function appenv-list {
	_appenv_list "$@"
}

function appenv-loaded {
	_appenv_loaded "$@"
}

function appenv-name {
	_appenv_name "$@"
}

function appenv-declares {
	_appenv_declares "$@"
}

# === MAIN ====================================================================

function appenv-load {
	local SCRIPT
	if [ -z "$1" ]; then
		SCRIPT=$(cat /dev/stdin | "$APPENV_LIB"/merge.bash)
	else
		FILE_PATH=$(_appenv_locate "$1")
		if [ -z "$FILE_PATH" ]; then
			_appenv_error "appenv-load[bash]: Cannot locate an appenv file like: $1"
		elif [ -e "$FILE_PATH" ]; then
			SCRIPT=$(. "$APPENV_LIB"/merge.bash "$FILE_PATH")
		else
			_appenv_error "_appenv-load[bash]: Could not resolve file $1 to $FILE_PATH"
		fi
	fi
	eval "${SCRIPT}"
	if [ -n "$APPENV_POST" ]; then
		eval "$APPENV_POST"
		unset APPENV_POST
	fi

}

function appenv-autoload {
	local FILE
	for FILE in $(appenv-list .); do
		_appenv_log "⛀ $(_appenv_name "$FILE") → $(basename $(dirname "$FILE"))/$(basename "$FILE") "
		appenv-load "$FILE"
	done
}

function appenv {
	local NAME
	if [ -z "$1" ]; then
		found=""
		for NAME in $(appenv-list .); do
			if [ -e "$NAME" ]; then
				appenv-load "$NAME"
				found=1
				break
			fi
		done
		if [ -z "$found" ]; then
			_appenv_error "Cannot find an .appenv file in the current directory or its ancestors"
		fi
	else
		for NAME in "$@"; do
			appenv-load "$NAME"
		done
	fi
}


# EOF
