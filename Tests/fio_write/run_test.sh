#Config collected info as well

TBASE=/homes/borispi/bTestSuite/
[ ! -e "$TBASE" ] && echo "base directory is not at $TBASE" && exit -1
[ -z "$OUT_FILE" ] && OUT_FILE=/tmp/
#rm -rf $OUT_FILE/*

Test=$1
[ -z "$Test" ] && echo "$0 ERROR: not test defined" && exit -1;
[  ! -e "$Test/test.sh" ] && echo "No File" && exit -1

echo "source $Test/config.sh"
source $Test/config.sh >> $OUT_FILE/test_raw.txt
[ -z "$repeat" ] && repeat=1
[ -z "$DELAY" ] && DELAY=10
[ -z "$RAMP" ] && RAMP=10

export TIME=30

rm -rf $OUT_FILE/result.txt

echo "$date starting ($Test $repeat [$DELAY])"
for i in `seq 1 $repeat`; do
	date=`date +"%H:%M.%s:"`
	export OUT_FILE=$OUT_FILE
	export OUTPUT=$OUT_FILE
	export RAMP=$RAMP
	echo "Sock: $SOCK_SIZE"
	$Test/test.sh >> $OUT_FILE/test_raw.txt &
	testid=$!
	echo "$date $Test/test.sh & $OUT_FILE"
	sleep $DELAY
	if [ "$TRACE" == "1" ]; then
		sudo -E $TBASE/DataCollector/collect_nvme.sh &>> $OUT_FILE/result.txt
		echo "collect done"
	else
		echo "skipping trace"
	fi
	# collection is ±40sec
	echo "$date waiting for test and collector ($Test)"
	if [ -e $Test/wait.sh ]; then
                echo "using $Test/wait.sh"
                $Test/wait.sh
        else
		echo "using sleep $[$RAMP+$TIME-$DELAY]"
		sleep $[$RAMP+$TIME-$DELAY]
		sleep 5 # write output
        fi
	#echo "$date running post ($Test)"
	#DataCollector/post_process.sh &>> $OUT_FILE/post.txt
done
date=`date +"%H:%M.%s:"`
echo "$date Done ($Test)"
