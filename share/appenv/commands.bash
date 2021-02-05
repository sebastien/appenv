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
# _appenv.command.bash

# === COLORS ==================================================================

# SEE: http://stackoverflow.com/questions/5947742/how-to-change-the-output-color-of-echo-in-linux
GREEN='\033[38;5;196m'
GREEN_BOLD='\033[1;38;5;196m'

GREEN='\033[38;5;82m'
GREEN_BOLD='\033[1;38;5;82m'

YELLOW='\033[38;5;220m'
YELLOW_BOLD='\033[1;38;5;220m'

BLUE='\033[38;5;45m'
BLUE_BOLD='\033[1;38;5;45m'

NORMAL='\033[0m' # No Color
NC="$NORMAL"

# === PATHS ==================================================================

SRC=${BASH_SOURCE[0]}
BASE=`dirname  $SRC`

# -----------------------------------------------------------------------------
#
# HELPERS
#
# -----------------------------------------------------------------------------

function _appenv_error {
	>&2 echo -e "${RED}[!] ${RED_BOLD}${@}${NC}"
}

function _appenv_log {
	echo -e "${YELLOW}${@}${NC}"
}

function _appenv_out {
	echo -e "${@}${NC}"
}

function _appenv_output {
	local OUT
	local ERR
	if [ -e "$1" ]; then
		OUT=`cat $1`
	else
		OUT=""
	fi
	if [ -e "$2" ]; then
		ERR=`cat $2`
	else
		ERR=""
	fi
	if [ -n "$ERR" ]; then
		_appenv_error $ERR
	elif [ -n "$OUT" ]; then
		_appenv_out $OUT
	fi
	if [ -e "$1" ]; then
		unlink $1
	fi
	if [ -e "$2" ]; then
		unlink $2
	fi
}

# -----------------------------------------------------------------------------
#
# HIGH-LEVEL API
#
# -----------------------------------------------------------------------------

function _appenv_locate {
	local APP
	local NAME=$1
	if [ -z "$NAME" ]; then
		# Name is empty, so we're looking for an .appenv
		# file
		if [ -e .appenv ]; then
			echo .appenv
		else
			_appenv_error "Cannot locate default .appenv file"
		fi
	elif [ -f "$NAME" ]; then
		#  The given name is a file, so we list is as is
		echo "$NAME"
	elif [ -d "$NAME" ] && [ -e "$NAME/.appenv" ]; then
		# It's a directory, so we return the nested .appenv, if any
		echo "$NAME/.appenv"
	elif [ -L "$NAME" ]; then
		# It's a link, which is like a file, so we resuturn as-is
		echo "$NAME"
	else
		# it's not found, so we need to list all the available append
		# and grep the ones that match the given name.
		local FOUND=false
		for APP in $(_appenv_list); do
			if [ -n "`_appenv_names $APP | xargs -n1 echo | grep -e \"^$NAME$\"`" ]; then
				echo "$APP"
				FOUND=true
				break
			fi
		done
		if [ "$FOUND" == "false" ]; then
			_appenv_error "_appenv_locate: Cannot locate appenv file: $NAME"
		fi
	fi
}

function _appenv_list {
	local APP=0
	local DIR=$1
	if [ -z "$DIR" ]; then
		DIR=$(pwd)
	fi
	local PARENT
	PARENT=$(dirname "$(readlink -f "$DIR")")
	if [ -d "$DIR"/.appenv ]; then
		for APP in "$DIR"/.appenv/*.appenv.sh; do
			if [ -e "$APP" ]; then
				echo "$APP"
			fi
		done
	elif [ -f "$DIR"/.appenv ]; then
		readlink -f "$DIR/.appenv"
	fi
	if [ -n "$PARENT" ] && [ "$PARENT" != "/" ]; then
		_appenv_list "$PARENT"
	fi
}


function _appenv_name {
	_appenv_names "$1"
}

function _appenv_names {
	local FILE=$(_appenv_locate "$1")
	local NAME
	if [ -e "$FILE" ]; then
		NAME=$(grep appenv_name < "$FILE" | awk '{print $2}')
	fi
	if [ -n "$NAME" ]; then
		echo "$NAME"
	fi
	NAME=$(echo "$1" | sed -E "s/(.*\/)?(auto\-[0-9]+\-)?(.*)\.appenv\.sh/\3/")
	if [ -n "$NAME" ]; then
		echo "$NAME"
	fi
}

function _appenv_declares {
	local NAME
	if [ -f "$1" ]; then
		for NAME in `cat $1 | grep appenv_declare | awk '{print $2}'`; do
			if [ -z "$NAME" ]; then
				NAMES=`basename $1 | cut -d. -f1`
			fi
			echo "$NAME"
		done
	else
		_appenv_error "File does not exist: $1"
	fi
	unset NAME
}

## function#_appenv_load
##   param#FILE_PATH: The shell script to source, by path or by name
##   desc|texto
##      Tries to locate the `FILE_PATH` using `_appenv_locate` and
##      then
##      .appenv file) script, merging its effects into the current
##      environment. This will take care of cd'ing into the source
##      file so that relative paths will be resolved.
##   :
function _appenv_load {
	local FILE_PATH
	FILE_PATH=$(_appenv_locate "$1")
	if [ -z "$FILE_PATH" ]; then
		_appenv_error "_appenv_load: Cannot locate an appenv file like: $1"
	elif [ -e "$FILE_PATH" ]; then
		_appenv_source "$FILE_PATH"
	else
		_appenv_error "_appenv_load: Could not resolve file $1 to $FILE_PATH"
	fi
}

function _appenv_unload {
	_appenv_error "appenv_unload: Not implemented yet"
}

function _appenv_loaded {
	local APP
	# FIXME: This does not seem to work
	for APP in ${APPENV_LOADED//:/}; do
		echo "$APP"
	done
}

## function#_appenv_source
##   param#FILE_PATH: The shell script to source
##   desc|texto
##      Sources the given shell script, which will execute the (presumably
##      .appenv file) script, merging its effects into the current
##      environment. This will take care of cd'ing into the source
##      file so that relative paths will be resolved.
##   :
function _appenv_source {
	local FILE_PATH="$1"
	if [ ! -e "$FILE_PATH" ]; then
		_appenv_error: "_appenv_source: Given file does not exists '$FILE_PATH'"
	else
		# This basically resolves the original FILE_PATH, cd to it, sources
		# it and then goes back to the current directory.
		local CUR_DIR="$PWD"
		local CUR_FILE="$APPENV_FILE"
		SUB_FILE=$(readlink -f "$FILE_PATH")
		if [ -z "$SUB_FILE" ]; then
			_appenv_error "appenv_source: Could not resolve file '$FILE_PATH'"
		fi
		local SUB_DIR
		SUB_DIR=$(dirname "$SUB_FILE")
		if [ -d "$SUB_DIR" ]; then
			cd "$SUB_DIR" || return
			export APPENV_FILE=$SUB_FILE
			export APPENV_DIR
			APPENV_DIR=$(dirname "$SUB_FILE")
			source "$SUB_FILE"
			APPENV_FILE=$CUR_FILE
			APPENV_DIR=$(dirname "$CUR_FILE")
			cd "$CUR_DIR" || return
		else
			_appenv_error "appenv_source: Could not find directory '$SUB_DIR'"
		fi
	fi
}

# -----------------------------------------------------------------------------
#
# CRITICAL PARTS/MECHANICS
#
# -----------------------------------------------------------------------------

function _appenv_capture {
	"$APPENV_PYTHON" -c "import os,sys,json;d=(dict((_,os.environ[_]) for _ in sorted(os.environ) if not _.startswith('BASH_') and not _.startswith('fish_') and not _.startswith('_')));sys.stdout.write(json.dumps(d))"
}

function _appenv_diff {
	echo "$1" | "$APPENV_PYTHON" -c "import json,sys,os;b=json.loads(sys.stdin.read());d=dict((_,os.environ[_]) for _ in os.environ if not _.startswith('BASH_') and not _.startswith('fish_') and not _.startswith('_') and b.get(_)!=os.environ[_]);[sys.stdout.write('_appenv_set \"{0}\" \"{1}\";'.format(v,k)) for v,k in d.items()]"
}

# EOF
