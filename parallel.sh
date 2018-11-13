pidfile=$(mktemp /tmp/pid.XXXXXXXXX)
resfile=$(mktemp /tmp/res.XXXXXXXXX)

# Use it as bash xxx.sh <procs> <Command> <args of Command's args>
# Eg: bash xxx.sh 3.sh    3     "mv "     "aa.c aa.c.2" "bb.c bb.c.2" etc...
# STDOUT would be redirect to tmpfile and output when finished
# STDERR is as usual

POOLSIZE=$1;  shift;
COMMAND="$1"; shift;

(>&2 echo "[INFO] Processing $# files via $POOLSIZE command pool， Command is \""${COMMAND}"\"")

arr=()

for i in $*; do
    ( $COMMAND $i >>$resfile &  echo $! >>$pidfile;  )
    arr+=( $(tail -n 1 $pidfile) )

    while [ ${#arr[@]} -ge  $POOLSIZE ]; do
        sleep 1
	tmp=()
        for ((i=0; i<${#arr[@]}; i++)); do
             if  ( kill -0 ${arr[$i]} >/dev/null 2>&1 )  ; then
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
rm -f $resfile $pidfile 