#!/usr/bin/env bash
local PREFIX=~/.local
local FILES=appenv.bash appenv.fish appenv.lib/api.bash appenv.lib/commands.bash appenv.lib/run.bash appenv.lib/merge.bash
local BASE=https://raw.githubusercontent.com/sebastien/appenv/
if [ $1 == "uninstall" ]; then
	for FILE in $FILES; do
		FILE=$PREFIX/bin/$FILE
		if [ -e FILE ]; then
			echo Removing $FILE
			unlink $FILE
		fi
	done
else
	if [ ! -d $PREFIX/bin ]; then
		mkdir -p $PREFIX/bin
	fi
	for FILE in $FILES; do
		echo Installing $BASE/bin/$FILE → $PREFIX/bin/$FILE
		curl $BASE/bin/$FILE > $PREFIX/bin/$FILE
	done
	chmod +x $BASE/bin/appenv.bash
	chmod +x $BASE/bin/appenv.fish
fi
# EOF
