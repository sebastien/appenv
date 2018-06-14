#!/usr/bin/env bash
PREFIX=~/.local
FILES="bin/appenv.bash bin/appenv.fish share/appenv/api.bash share/appenv/commands.bash share/appenv/run.bash share/appenv/merge.bash"
BASE="https://raw.githubusercontent.com/sebastien/appenv/master"
METHOD="copy"

if [ "$1" = "uninstall" ]; then
	for FILE in $FILES; do
		FILE="$PREFIX/$FILE"
		if [ -e "$FILE" ]; then
			echo "Removing $FILE"
			unlink "$FILE"
		fi
	done
	exit 0
elif [ "$1" = "link" ]; then
	METHOD="link"
fi

if [ ! -d $PREFIX/bin ]; then
	mkdir -p $PREFIX/bin
fi
for FILE in $FILES; do
	DST=$PREFIX/$FILE
	DIR=$(dirname "$DST")
	if [ ! -d "$DIR" ]; then
		mkdir -p "$DIR"
	fi
	if [ -f "$FILE" ]; then
		SRC="$FILE"
		if [ "$METHOD" = "link" ]; then
			echo "Linking $SRC → $DST"
			ln -sfr "$SRC" "$DST"
		else
			echo "Copying $SRC → $DST"
			cp -a "$SRC" "$DST"
		fi
	else
		SRC="$BASE/$FILE"
		echo "Installing $SRC → $DST"
		curl --silent "$SRC" > "$DST"
	fi
done
chmod +x "$PREFIX/bin/appenv.bash"
chmod +x "$PREFIX/bin/appenv.fish"
# EOF
