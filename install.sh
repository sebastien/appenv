#!/usr/bin/env bash
PREFIX=~/.local
FILES="bin/appenv.bash bin/appenv.fish share/appenv/api.bash share/appenv/commands.bash share/appenv/run.bash share/appenv/merge.bash"
BASE="https://raw.githubusercontent.com/sebastien/appenv/master"

if [ "$1" = "uninstall" ]; then
	for FILE in $FILES; do
		FILE=$PREFIX/$FILE
		if [ -e $FILE ]; then
			echo Removing $FILE
			unlink $FILE
		fi
	done
else
	if [ ! -d $PREFIX/bin ]; then
		mkdir -p $PREFIX/bin
	fi
	for FILE in $FILES; do
		DST=$PREFIX/$FILE
		DIR=`dirname $DST`
		if [ ! -d $DIR ]; then
			mkdir -p $DIR
		fi
		if [ -f $FILE ]; then
			SRC=$FILE
			echo Copying $SRC → $DST
			cp -a $SRC $DST
		else
			SRC=$BASE/$FILE
			echo Installing $SRC → $DST
			curl $SRC > $DST
		fi
	done
	chmod +x $PREFIX/bin/appenv.bash
	chmod +x $PREFIX/bin/appenv.fish
fi
# EOF
