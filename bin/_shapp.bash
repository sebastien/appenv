#!/usr/bin/env bash
#
# Executes the given shell script and echoes a list of commands to be evaluated
# by the calling shell to update its environment.
#
# Usage: ./_shapp.bash <FILE>.shapp
#

# === MAIN ====================================================================
BEFORE=`python3 -c "import os,sys,json;d=(dict((_,os.environ[_]) for _ in sorted(os.environ)));print(json.dumps(d))"`
source $1
AFTER=`echo $BEFORE | python3 -c "import json,sys,os;b=json.loads(sys.stdin.read());d=dict((_,os.environ[_]) for _ in os.environ if b.get(_)!=os.environ[_]);[print('shapp_set \"{0}\" \"{1}\";'.format(v,k)) for v,k in d.items()]"`
echo $AFTER

# EOF
