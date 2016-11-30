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
# _appenv.api.bash -- Bash implementation fo the appenv shell API.
#
# SEE: http://stackoverflow.com/questions/229551/string-contains-in-bash

function appenv_declare {
	NAME=$1
	VALUE=$2
	CURRENT=`printenv $1`
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
	NAME=$1
	VALUE=$2
	CURRENT=`printenv $1`
	# "Compatible answer"
	if [ -z "$CURRENT" ]; then
		export ${NAME}=${VALUE}
	elif [ -n "${CURRENT##*$VALUE*}" ] ;then
		export ${NAME}=${CURRENT}:${VALUE}
	fi
}

function appenv_prepend {
	NAME=$1
	VALUE=$2
	CURRENT=`printenv $1`
	if [ -z "$CURRENT" ]; then
		export ${NAME}=${VALUE}
	elif [ -n "${CURRENT##*$VALUE*}" ] ;then
		export ${NAME}=${VALUE}:${CURRENT}
	fi
}

function appenv_remove {
	NAME=$1
	VALUE=$2
	CURRENT=`printenv $1`
	UPDATED=${CURRENT//$VALUE/}
	if [ "$UPDATED" != "$CURRENT" ]; then
	 	export ${NAME}=${UPDATED}
	fi
}


function appenv_clear {
	export $1=
}

# EOF
