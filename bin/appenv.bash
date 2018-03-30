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

if [ -z `which python` ]; then
	echo 'appenv: `python` is required'; exit
fi

# === GLOBALS =================================================================

BASE=$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")
export APPENV_SHELL=$(which bash)

# === API =====================================================================
# Sets the given environment variable to the given value

source "$BASE/../share/appenv/commands.bash"

# === OVERRIDES ===============================================================

function _appenv_set {
	NAME=$1
	VALUE=$2
	eval "export ${NAME}=\"${VALUE}\""
}

# === WRAPPERS ================================================================

function appenv-locate {
	_appenv_locate $@
}

function appenv-list {
	_appenv_list $@
}

function appenv-loaded {
	_appenv_loaded $@
}

function appenv-name {
	_appenv_name $@
}

function appenv-declares {
	_appenv_declares $@
}

# === MAIN ====================================================================

function appenv-import {
	local SCRIPT
	# NOTE: We need to call `appenv_import` directly so as to not create
	# a sub-shell
	if [ -z "$1" ]; then
		SCRIPT=`cat /dev/stdin | $BASE/../appenv/merge.bash`
	else
		SCRIPT=`. $BASE/../appenv/merge.bash $1`
	fi
	eval "${SCRIPT}"
}

function appenv-load {
	local NAME=`_appenv_locate $1`
	if [ -e $NAME ]; then
		appenv-import $NAME
	else
		_appenv_error "Cannot find appenv file $1"
	fi
	if [ ! -z "$APPENV_POST" ]; then
		_appenv_log "appenv▸post ← $APPENV_POST"
		eval "$APPENV_POST"
	fi
	unset APPENV_POST
}

function appenv-autoload {
	local FILE
	for FILE in `appenv-list .`; do
		_appenv_log "⛀ `_appenv_name $FILE` → `basename \`dirname $FILE\``/`basename $FILE` "
		appenv-load $FILE
	done
}

function appenv {
	if [ -z "$1" ]; then
		local NAME=`appenv-list . | grep -v "$HOME/.appenv" | head -n1`
		if [ -e "$NAME" ]; then
			appenv-load $NAME
		else
			_appenv_error "Cannot find an .appenv file in the current directory or its ancestors"
		fi
	else
		for NAME in $@; do
			appenv-load $NAME
		done
	fi
}

# EOF
