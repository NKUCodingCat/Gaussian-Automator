PY_Script=$( cat <<-END
import cclib
import os
import argparse
parser = argparse.ArgumentParser(description='Process a bunch of log files')
parser.add_argument('Gau_log', nargs=1) 
args = parser.parse_args()
parser = cclib.io.ccopen(args.Gau_log[0])
data = parser.parse()
print os.path.realpath(args.Gau_log[0]), "\t\t",
if ("optdone" in data.__dict__) and ("scfenergies" in data.__dict__) and data.optdone:
    print data.scfenergies[-1]/27.21138505
else:
    print "FAILED"
END
)

POOLSIZE=16
pidfile=$(mktemp /tmp/pid.XXXXXXXXX)
resfile=$(mktemp /tmp/res.XXXXXXXXX)
PY_file=$(mktemp /tmp/PY_.XXXXXXXXX)

echo -e "$PY_Script" >$PY_file
(>&2 echo "[INFO] Processing $# files with $POOLSIZE procs pool")

arr=()

for i in $*; do
    ( python $PY_file "$i" >>$resfile &  echo $! >>$pidfile;  )
    arr+=( $(tail -n 1 $pidfile) )

    while [ ${#arr[@]} -ge $POOLSIZE ]; do
        sleep 0.5
	tmp=()
        for ((i=0; i<${#arr[@]}; i++)); do
             if  ( kill -0 ${arr[$i]} >/dev/null 2>&1 )  ; then
                # echo "Checking" ${arr[$i]} 
		tmp+=( ${arr[$i]} )
             fi
	done
	arr=("${tmp[@]}")
    done
done 

cat $pidfile | while read line; do 
    while ( kill -0 "$line" >/dev/null 2>&1 ); do
        sleep 1
    done
done

cat $resfile
rm -f $resfile $pidfile $PY_file

