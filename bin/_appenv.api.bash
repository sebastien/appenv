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
# _appenv.api.bash -- Bash implementation fo the appenv environment API.
#
# SEE: http://stackoverflow.com/questions/229551/string-contains-in-bash

# === VERSION =================================================================

APPENV_API="0.0.0"

BASE=`readlink -f \`dirname ${BASH_SOURCE[0]}\``
source $BASE/_appenv.command.bash

# -----------------------------------------------------------------------------
#
# LOW-LEVEL API
#
# -----------------------------------------------------------------------------

function appenv_declare {
	local NAME=$1
	local VALUE=$2
	local CURRENT=`printenv $1`
	if test -z "$VALUE"; then
		VALUE="true"
	fi
	if [ "$VALUE" != "$CURRENT" ]; then
	 	export ${NAME}=${VALUE}
	 	export ${NAME}=${VALUE}
	else
		exit
	fi
}

function appenv_append {
	local NAME=$1
	local VALUE=$2
	local CURRENT=`printenv $1`
	# "Compatible answer"
	if [ -z "$CURRENT" ]; then
		export ${NAME}=${VALUE}
	elif [ -n "${CURRENT##*$VALUE*}" ] ;then
		export ${NAME}=${CURRENT}:${VALUE}
	fi
}

function appenv_prepend {
	local NAME=$1
	local VALUE=$2
	local CURRENT=`printenv $1`
	if [ -z "$CURRENT" ]; then
		export ${NAME}=${VALUE}
	elif [ -n "${CURRENT##*$VALUE*}" ] ;then
		export ${NAME}=${VALUE}:${CURRENT}
	fi
}

function appenv_remove {
	local NAME=$1
	local VALUE=$2
	local CURRENT=`printenv $1`
	local UPDATED=${CURRENT//$VALUE/}
	if [ "$UPDATED" != "$CURRENT" ]; then
	 	export ${NAME}=${UPDATED}
	fi
}

function appenv_set {
	local NAME=$1
	local VALUE=$2
 	export ${NAME}=${VALUE}
}

function appenv_clear {
	export $1=
}

function appenv_log {
	echo -e "${YELLOW}${@}${NC}"
}

function appenv_error {
	>&2 echo -e "${@}"
}

# EOF