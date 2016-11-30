#!/usr/bin/env fish
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
# _appenv.fish -- Fish shell implementation of the appenv commands.
# This loads one or more bash-compatible scripts given as argument and 
# propagates the changed made to the environnemnt back into 
# the current Fish shell session.

# === REQUIREMENTS ===========================================================

if test -z (which python)
	echo "appenv: `python` is required"; exit
end
if test -z (which bash)
	echo "appenv: `bash` is required"; exit
end

# === GLOBALS =================================================================

set BASE (dirname  (status -f))
set FILE (basename (status -f))

# === API ====================================================================
# Sets the given environment variable to the given value
function _appenv_set
	set NAME  $argv[1]
	set VALUE $argv[2]
	switch $NAME
		case 'PATH'
			# In Fish, PATH has a special handling
			# https://fishshell.com/docs/current/tutorial.html#tut_path
			set COMMAND "set -gx PATH " (echo $VALUE | sed 's|:| |g') '$PATH'
			eval $COMMAND
		case '*'
			set COMMAND "set -gx $NAME $VALUE"
			eval $COMMAND
	end
end

# === MAIN ====================================================================

function appenv-load
	# Runs the given Bash command and merges-in the changes to the environment.
	if test -z $argv[1]
		echo Usage: appenv-load '<FILE>.appenv.sh'
	else
		for file in $argv
			# echo "appenv-load: loading" $file
			set SCRIPT (bash $BASE/_appenv.merge.bash $file)
			eval $SCRIPT
		end
	end
end

function appenv-autoload
	if test -z $path
		set path .appenv
	end
	if test -d $path
		appenv-autoload .appenv/*.appenv.sh
	else if test -e $path
		set path (readlink -e $path)
		echo "appenv: autoload" (set_color blue)(basename (dirname $path))/(basename $path) (set_color normal)
		set -gx APPENV_FILE $path
		appenv-load $path
	end
end
# EOF
