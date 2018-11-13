POOLSIZE=5
pidfile=$(mktemp /tmp/pid.XXXXXXXXX)
resfile=$(mktemp /tmp/res.XXXXXXXXX)
SH_file=$(mktemp /tmp/SH_.XXXXXXXXX)

cat ./run-g09.sh >$SH_file
(>&2 echo "[INFO] Processing $# files via $POOLSIZE command pool")

arr=()

for i in $*; do
    ( bash $SH_file "$i" >>$resfile &  echo $! >>$pidfile;  )
    arr+=( $(tail -n 1 $pidfile) )

    while [ ${#arr[@]} -ge $POOLSIZE ]; do
        sleep 60
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
        sleep 60
    done
done

cat $resfile
rm -f $resfile $pidfile $PY_file

