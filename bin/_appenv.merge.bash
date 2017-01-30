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
# _appenv.merge.bash -- executes the given shell script and echoes a list of
# appenv API commands to be evaluated by the calling shell
# to update its environment.
#
# Usage: ./_appenv.merge.bash <FILE>.appenv.sh?

# We source appenv's bash API if not already there
# if [ -z $APPENV_API ]; then
# 	source `dirname ${BASH_SOURCE[0]}`/_appenv.api.bash
# fi
source `dirname ${BASH_SOURCE[0]}`/_appenv.api.bash

# === MAIN ====================================================================
OUTFILE=`mktemp`
ERRFILE=`mktemp`

# We capture the current environment
BEFORE=`_appenv_capture`

if [ -z $1 ]; then
	cat /dev/stdin
	# When called with no argument, we eval stdin 
	# eval `cat /dev/stdin` 1>> $OUTFILE 2>> $ERRFILE
else
	# When called with an argument, we interpret the first one
	# FIXME: Warn about other arguments being ignored.
	FILE=`readlink -f $1`
	appenv_append APPENV_LOADED `readlink -f $1`
	# We execute the appenv script, capturing both output and error
	. $1 1>> $OUTFILE 2>> $ERRFILE
fi

# We get the diff with BEFORE
AFTER=`_appenv_diff "$BEFORE"`

# Output the difference
echo $AFTER

# And output any error message that we might have found
echo _appenv_output $OUTFILE $ERRFILE

# EOF
