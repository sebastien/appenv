#!/usr/bin/env bash
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
# _appenv.merge.bash -- executes the given shell script and echoes a list of
# commands to be evaluated by the calling shell to update its environment.
#
# Usage: ./_appenv.merge.bash <FILE>.appenv.sh
#
source `dirname $0`/_appenv.api.bash
# === MAIN ====================================================================
BEFORE=`python -c "import os,sys,json;d=(dict((_,os.environ[_]) for _ in sorted(os.environ)));sys.stdout.write(json.dumps(d))"`
. $1 > /dev/null
AFTER=`echo $BEFORE | python -c "import json,sys,os;b=json.loads(sys.stdin.read());d=dict((_,os.environ[_]) for _ in os.environ if b.get(_)!=os.environ[_]);[sys.stdout.write('_appenv_set \"{0}\" \"{1}\";'.format(v,k)) for v,k in d.items()]"`
echo $AFTER
# EOF
