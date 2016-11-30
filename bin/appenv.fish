#!/usr/bin/env fish

# appenv.fish -- Fish shell implementation of SHell APPlications.
# This loads one or more bash-compatible scripts given as argument and 
# propagates the changed made to the environnemnt back into 
# the current Fish shell session.


# === REQUIREMENTS ===========================================================

if test -z (which python3)
	echo "appenv: `python3` is required"; exit
end
if test -z (which bash)
	echo "appenv: `bash` is required"; exit
end

# === GLOBALS =================================================================

set BASE (dirname  (status -f))
set FILE (basename (status -f))

# === API ====================================================================
# Sets the given environment variable to the given value
function appenv_set
	set NAME  $argv[1]
	set VALUE $argv[2]
	switch $NAME
		case 'PATH'
			# In Fish, PATH has a special handling
			# https://fishshell.com/docs/current/tutorial.html#tut_path
			set COMMAND "set -x PATH " (echo $VALUE | sed 's|:| |g') '$PATH'
			eval $COMMAND
		case '*'
			echo SET $NAME $VALUE
			set -x $argv[1] $argv[2]
	end
end

# === MAIN ====================================================================

# Runs the given Bash command and merges-in the changes to the environment.
if test -z $argv[1]
	echo Usage: $FILE '<FILE>.appenv'
	exit -1
else
	for file in $argv
		echo "appenv: loading" $file
		set SCRIPT (bash $BASE/_appenv.bash $file)
		eval $SCRIPT
	end
end

# EOF


