#!/usr/bin/env fish

# Sets the given environment variable to the given value
function shapp_set
	set NAME  $argv[1]
	set VALUE $argv[2]
	switch $NAME
		case 'PATH'
			# In Fish, PATH has a special handling
			# https://fishshell.com/docs/current/tutorial.html#tut_path
			set COMMAND "set PATH " (echo $VALUE | sed 's|:| |g') '$PATH'
			eval $COMMAND
		case '*'
			echo SET $NAME $VALUE
			set -g $argv[1] $argv[2]
	end
end

# Runs the given Bash command and merges-in the changes to the environment.

set SCRIPT (bash ./shapp-merge.bash $argv[1])
eval $SCRIPT

# EOF


