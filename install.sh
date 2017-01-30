#!/usr/bin/env bash
PREFIX=~/.local
FILES="bin/appenv.bash bin/appenv.fish lib/appenv/api.bash lib/appenv/commands.bash lib/appenv/run.bash lib/appenv/merge.bash"
BASE="https://raw.githubusercontent.com/sebastien/appenv"
if [ "$1" = "uninstall" ]; then
	for FILE in $FILES; do
		FILE=$PREFIX/bin/$FILE
		if [ -e $FILE ]; then
			echo Removing $FILE
			#unlink $FILE
		fi
	done
else
	if [ ! -d $PREFIX/bin ]; then
		mkdir -p $PREFIX/bin
	fi
	for FILE in $FILES; do
		SRC=$BASE/$FILE
		DST=$PREFIX/$FILE
		DIR=`dirname $DST`
		echo Installing $SRC → $DST
		if [ ! -d $DIR ]; then
			mkdir -p $DIR
		fi
		curl $SRC > $DST
	done
	 chmod +x $BASE/bin/appenv.bash
	# chmod +x $BASE/bin/appenv.fish
fi
# EOF
