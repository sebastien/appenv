#!/usr/bin/bash
if test -z $APP_EXAMPLE; then
	export APP_EXAMPLE=$HOME/.local/share/example
	export PATH=$APP_EXAMPLE/bin:$PATH
	export MANPATH=$APP_EXAMPLE/share/man:$MANPATH
fi
#EOF
