#Config collected info as well

TBASE=$TBASE/TestSuite/
[ ! -e "$TBASE" ] && echo "base directory is not at $TBASE" && exit -1
[ -z "$OUT_FILE" ] && OUT_FILE=/tmp/
#rm -rf $OUT_FILE/*

Test=$1
[ -z "$Test" ] && echo "$0 ERROR: not test defined" && exit -1;
[  ! -e "$Test/test.sh" ] && echo "No File" && exit -1

if [ -z "$NOCONFIG" ]; then
	echo "source $Test/config.sh"
	source $Test/config.sh >> $OUT_FILE/test_raw.txt
fi
[ -z "$repeat" ] && repeat=1
#[ -z "$DELAY" ] && DELAY=20
[ -z "$RAMP" ] && RAMP=20

export TIME=30

rm -rf $OUT_FILE/result.txt

echo "$date starting ($Test $repeat [$RAMP])"
for i in `seq 1 $repeat`; do
	date=`date +"%H:%M.%s:"`
	export OUT_FILE=$OUT_FILE
	export OUTPUT=$OUT_FILE
	export RAMP=$RAMP
	echo "Sock: $SOCK_SIZE"
	$Test/test.sh >> $OUT_FILE/test_raw.txt &
	testid=$!
	echo "$date $Test/test.sh & $OUT_FILE"
	sleep $RAMP
	if [ "$TRACE" == "1" ]; then
		sudo -E $TBASE/DataCollector/collect_nvme.sh &>> $OUT_FILE/result.txt
		echo "collect done"
	else
		sudo -E $TBASE/DataCollector/collect_net_cpu.sh &>> $OUT_FILE/result.txt
		echo "skipping trace"
	fi
	# collection is ±40sec
	echo "$date waiting for test and collector ($Test)"
	if [ -e $Test/wait.sh ]; then
                echo "using $Test/wait.sh"
                $Test/wait.sh
        else
		echo "using sleep $TIME"
		sleep $TIME
		sleep 5 # write output
        fi
	#echo "$date running post ($Test)"
	#DataCollector/post_process.sh &>> $OUT_FILE/post.txt
done
date=`date +"%H:%M.%s:"`
echo "$date Done ($Test)"
