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

# === OVERRIDES ===============================================================

function _appenv_api
	bash $BASE/_appenv.run.bash $argv
end

function _appenv_output
	_appenv_api output $argv
end

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


# === WRAPPERS ================================================================

function appenv-locate
	_appenv_api locate $argv
end

function appenv-list
	_appenv_api list $argv
end

function appenv-loaded
	_appenv_api loaded $argv
end

function appenv-name
	_appenv_api name $argv
end

function appenv-declares
	_appenv_api declares $argv
end

# === MAIN ====================================================================

function appenv-import
	if test -z $argv[1]
		set SCRIPT (cat /dev/stdin | bash $BASE/_appenv.merge.bash)
	else
		set SCRIPT (bash $BASE/_appenv.merge.bash $argv[1])
	end
	eval $SCRIPT
end

function appenv-load
	set NAME (appenv-locate $argv[1])
	if test -n $NAME
		if test -f $NAME
			appenv-import $NAME
		else if test -d $NAME
			for SUBNAME in $NAME/*.appenv.sh
				appenv-import $NAME
			end
		else
			_appenv_api error "Cannot find appenv file " $NAME
		end
	end
end

function appenv-autoload
	for FILE in appenv-list .
		_appenv_api log "⛀ " (appenv-name $FILE) "→" (basename (dirname $FILE))/(basename $FILE)
		appenv-load $FILE
	end
end

function appenv
	if test -z $argv
		appenv-autoload
	else
		for NAME in $argv
			appenv-load $NAME
		end
	end
end

# EOF
