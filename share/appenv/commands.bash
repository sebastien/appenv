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
		if [ -e .appenv ]; then
			echo .appenv
		else
			_appenv_error "Cannot locate default .appenv file"
		fi
	elif [ -f "$NAME" ]; then
		echo $NAME
	elif [ -d "$NAME" -a -e $NAME/.appenv ]; then
		echo $NAME/.appenv
	elif [ -L "$NAME" ]; then
		echo $NAME
	else
		local FOUND=false
		for APP in `_appenv_list`; do
			if [ -n "`_appenv_names $APP | xargs -n1 echo | grep -e \"^$NAME$\"`" ]; then
				echo $APP
				FOUND=true
			fi
		done
		if [ "$FOUND" == "false" ]; then
			_appenv_error "Cannot locate appenv file: $NAME"
		fi
	fi
}

function _appenv_list {
	local APP=0
	local DIR=$1
	if [ -z "$DIR" ]; then
		DIR=`pwd`
	fi
	local PARENT=`dirname \`readlink -f $DIR\``
	if [ -d $DIR/.appenv ]; then
		for APP in $DIR/.appenv/*.appenv.sh; do
			if [ -e "$APP" ]; then
				echo $APP
			fi
		done
	elif [ -f $DIR/.appenv ]; then
		readlink -f $DIR/.appenv
	fi
	if [ -n "$PARENT" -a "$PARENT" != "/" ]; then
		_appenv_list $PARENT
	fi
}

function _appenv_name {
	_appenv_names $1 
}

function _appenv_names {
	local FILE=`_appenv_locate $1`
	local NAME
	if [ -e "$FILE" ]; then
		NAME=`cat $FILE | grep appenv_name | awk '{print $2}'`
	fi
	if [ -n "$NAME" ]; then
		echo $NAME
	fi
	NAME=`echo $1 | sed -E "s/(.*\/)?(auto\-[0-9]+\-)?(.*)\.appenv\.sh/\3/"`
	if [ -n "$NAME" ]; then
		echo $NAME
	fi
}

function _appenv_declares {
	local NAME
	if [ -f "$1" ]; then
		for NAME in `cat $1 | grep appenv_declare | awk '{print $2}'`; do
			if [ -z "$NAME" ]; then
				NAMES=`basename $1 | cut -d. -f1`
			fi
			echo $NAME
		done
	else
		_appenv_error "File does not exist: $1"
	fi
	unset NAME
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

function _appenv_capture {
	python -c "import os,sys,json;d=(dict((_,os.environ[_]) for _ in sorted(os.environ) if not _.startswith('BASH_')));sys.stdout.write(json.dumps(d))"
}

function _appenv_diff {
	echo $1 | python -c "import json,sys,os;b=json.loads(sys.stdin.read());d=dict((_,os.environ[_]) for _ in os.environ if not _.startswith('BASH_') and b.get(_)!=os.environ[_]);[sys.stdout.write('_appenv_set \"{0}\" \"{1}\";'.format(v,k)) for v,k in d.items()]"
}

# EOF 
