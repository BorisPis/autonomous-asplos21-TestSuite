#!/bin/bash

perf=$TBASE/linux/tools/perf/perf

IPERF=$TBASE/TestSuite/Apps/ssl/iperf
OPENSSL=$TBASE/TestSuite/Apps/ssl/openssl

[ -z "$dip1" ] && echo 'no dip2' && exit;
[ -z "$TIME" ] && TIME=10
[ -z "$RAMP" ] && RAMP=10
[ -z "$OUTPUT" ] && OUTPUT=/tmp
[ -z "$RECSIZE" ] && RECSIZE=16000
#[ -z "$MSGSIZE" ] && MSGSIZE=65536
[ -z "$MSGSIZE" ] && MSGSIZE=262144
[ -z "$ISENC" ] && ISENC=1
[ -z "$WAIT" ] && WAIT=false
[ -z "$OFFLOAD" ] && OFFLOAD=0
[ -z "$THREADS" ] && THREADS=1
[ -z "$PORT" ] && PORT=4444

echo "Connecting $dip1.."

mkdir $OUTPUT
sudo pkill -x iperf
ssh $loader1 pkill -x iperf
#sudo dmesg -C

case $OFFLOAD in
	0)
		echo no offload;
		sudo ethtool -K $if1 tls-hw-tx-offload off
		;;
	1)
		echo offload enabled;
		sudo ethtool -K $if1 tls-hw-tx-offload on
		;;
esac

if [ `hostname` == "gen-l-vrt-010.mtl.labs.mlnx" ]; then
    LCORES=( 0 0 0 0 0 0 )
    RCORES=( 0 1 2 6 7 8 )
elif [ `hostname` == "dante732" ]; then
    LCORES=( 0 0 0 0 0 0 )
    RCORES=( 0 2 4 6 8 10 )
else
    echo unknown hostname: `hostname`
    exit
fi

# Start server
if [ $ISENC == 1 ]; then
	for i in `seq 1 $THREADS`;
	do
		echo ssh -t $loader1 \"cd $IPERF\; LD_LIBRARY_PATH=$OPENSSL taskset -c ${RCORES[$i]} $IPERF/src/iperf -s -X -p $[$PORT + $i] \"
		ssh -t $loader1 "cd $IPERF; LD_LIBRARY_PATH=$OPENSSL taskset -c ${RCORES[$i]} $IPERF/src/iperf -s -X -p $[$PORT + $i] " &
	done
else
	# No threads for decryption test (IS_ENC=0)
	echo LD_LIBRARY_PATH=$OPENSSL taskset -c 0 $perf stat -D $[$RAMP*1000+1000] -a -C 0 -e task-clock,cycles,instructions,cache-misses -x, -o $OUTPUT/perf_stat.txt $IPERF/src/iperf -s --ktls 
	LD_LIBRARY_PATH=$OPENSSL taskset -c 0 $perf stat -D $[$RAMP*1000+1000] -a -C 0 -e task-clock,cycles,instructions,cache-misses -x, -o $OUTPUT/perf_stat.txt $IPERF/src/iperf -s -l $MSGSIZE --ktls &
	sleep $[$TIME+$RAMP+1] && sudo pkill -x iperf &
fi

sleep 1

echo "Running iperf client"
if [ $ISENC == 1 ]; then
	for i in `seq 1 $THREADS`;
	do
		echo "LD_LIBRARY_PATH=$OPENSSL taskset -c ${LCORES[$i]} $perf stat -D $[$RAMP*1000] -a -C ${LCORES[$i]} -e task-clock,cycles,instructions,cache-misses -x, -o $OUTPUT/perf_stat.txt $IPERF/src/iperf -c $dip1 -l $MSGSIZE -t $[$TIME+$RAMP] --tls --ktls --ktls_record_size=$RECSIZE -p $[$PORT + $i] | tee -a $OUTPUT/iperf.$i.txt &"
		LD_LIBRARY_PATH=$OPENSSL taskset -c ${LCORES[$i]} $perf stat -D $[$RAMP*1000] -a -C ${LCORES[$i]} -e task-clock,cycles,instructions,cache-misses -x, -o $OUTPUT/perf_stat.txt $IPERF/src/iperf -c $dip1 -l $MSGSIZE -t $[$TIME+$RAMP] --tls --ktls --ktls_record_size=$RECSIZE -p $[$PORT + $i] | tee -a $OUTPUT/iperf.$i.txt &
	done

	test_pid=$!
else
	echo ssh $loader1 \"cd $IPERF\; LD_LIBRARY_PATH=$OPENSSL taskset -c 0 $IPERF/src/iperf -c $ip1 -l $MSGSIZE -t $[$TIME+$RAMP] --tls --ktls --ktls_record_size=$RECSIZE\"
	ssh $loader1 "cd $IPERF; LD_LIBRARY_PATH=$OPENSSL taskset -c 0 $IPERF/src/iperf -c $ip1 -l $MSGSIZE -t $[$TIME+$RAMP] --tls --ktls --ktls_record_size=$RECSIZE" | tee -a $OUTPUT/iperf.txt &
#	ssh -t $loader1 "cd $IPERF; LD_LIBRARY_PATH=$OPENSSL taskset -c 0 $IPERF/src/iperf -c $ip1 -l $MSGSIZE -t $[$TIME+$RAMP] --tls" | tee -a $OUTPUT/iperf.txt &

	test_pid=$!

fi

if [ "$WAIT" == true ]; then
	echo 'waiting for iperf'
	wait $test_pid
fi
