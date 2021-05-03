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

set APPENV_BASE (dirname  (status -f))
set -gx APPENV_SHELL (which fish)
set -e  APPENV_POST

# === OVERRIDES ===============================================================

function _appenv_run
	bash $APPENV_BASE/../share/appenv/run.bash $argv
end

function _appenv_output
	_appenv_run output $argv
end

function _appenv_set
	set NAME  $argv[1]
	set VALUE $argv[2]
	switch $NAME
		case 'SHLVL'
			# We don't do anything, we want to absorb this one, otherwise
			# Fish will complain
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
	_appenv_run locate $argv
end

function appenv-list
	_appenv_run list $argv
end

function appenv-loaded
	_appenv_run loaded $argv
end

function appenv-name
	_appenv_run name $argv
end

function appenv-declares
	_appenv_run declares $argv
end

# === MAIN ====================================================================

function appenv-import
	if test -z $argv[1]
		set -gx APPENV_FILE /dev/stdin
		set -gx APPENV_DIR  ""
		set SCRIPT (cat /dev/stdin | bash $APPENV_BASE/../share/appenv/merge.bash)
	else
		set -gx APPENV_FILE $argv[1]
		set -gx APPENV_DIR  (dirname $argv[1])
		set SCRIPT (bash $APPENV_BASE/../share/appenv/merge.bash $argv[1])
	end
end

function appenv-load
	for FILE in $argv
		if test -z "$FILE"
			set -gx APPENV_FILE /dev/stdin
			set -gx APPENV_DIR  ""
			set SCRIPT (cat /dev/stdin | "$APPENV_BASE"/../appenv/merge.bash)
		else
			set FILE_PATH (_appenv_run locate "$FILE")
			if test -z $FILE_PATH
				_appenv_run error "appenv-load[fish]: Cannot locate an appenv file like: $FILE"
			elif test ! -e $FILE_PATH
				_appenv_run error "appenv-load[fish]: Could not access file '$FILE_PATH' resolved from '$FILE'"
			else
				set -gx APPENV_FILE $FILE_PATH
				set -gx APPENV_DIR  (dirname $FILE_PATH)
				set SCRIPT (bash $APPENV_BASE/../share/appenv/merge.bash "$FILE_PATH")
			end
		end
		if test ! -z "$SCRIPT";
			eval $SCRIPT
		end
		if test ! -z "$APPENV_POST";
			eval $APPENV_POST
		end
		set -e APPENV_POST
	end
end

function appenv-autoload
	set FILE (appenv-list . | head -n1)
	if test -e $FILE
		_appenv_run log "⛀ " (appenv-name $FILE) "→" (basename (dirname $FILE))/(basename $FILE)
		appenv-load $FILE
	end
end

function appenv
	if test -z $argv
		set NAME (appenv-list . | grep -v "$HOME/.appenv" | head -n1)
		if test -e $NAME
			appenv-load $NAME
		else
				_appenv_run error "Cannot find an .appenv file in the current directory or its ancestors"
		end
	else
		for NAME in $argv
			appenv-load $NAME
		end
	end
end

# EOF
