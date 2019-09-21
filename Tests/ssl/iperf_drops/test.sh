#!/bin/bash

perf=$TBASE/linux/tools/perf/perf

IPERF=$TBASE/TestSuite/Apps/ssl/iperf
OPENSSL=$TBASE/TestSuite/Apps/ssl/openssl

[ -z "$dip1" ] && echo 'no dip2' && exit;
[ -z "$TIME" ] && TIME=10
[ -z "$RAMP" ] && RAMP=5
[ -z "$OUTPUT" ] && OUTPUT=/tmp
[ -z "$RECSIZE" ] && RECSIZE=16000
#[ -z "$MSGSIZE" ] && MSGSIZE=65536
[ -z "$MSGSIZE" ] && MSGSIZE=262144
[ -z "$ISENC" ] && ISENC=1
[ -z "$WAIT" ] && WAIT=false
[ -z "$DROP" ] && DROP=0
[ -z "$THREADS" ] && THREADS=1
[ -z "$PORT" ] && PORT=4444
[ -z "$PARALLEL" ] && PARALLEL=1
# types: 0 - tcp, 1 - ktls, 2 - ktls_offload
[ -z "$TYPE" ] && TYPE=2

echo "Connecting $dip1.."

# Enable offload only for ktls_offload
if [ $TYPE == 2 ]; then
    echo "Enabling offload"
    if [ $ISENC == 1 ]; then
        sudo ethtool -K $if1 tls-hw-tx-offload on
        sudo ethtool -K $if1 tls-hw-rx-offload off
        ssh -t $loader1 sudo ethtool -K $dif1 tls-hw-tx-offload off
        ssh -t $loader1 sudo ethtool -K $dif1 tls-hw-rx-offload on
    else
        sudo ethtool -K $if1 tls-hw-tx-offload off
        sudo ethtool -K $if1 tls-hw-rx-offload on
        ssh -t $loader1 sudo ethtool -K $dif1 tls-hw-tx-offload on
        ssh -t $loader1 sudo ethtool -K $dif1 tls-hw-rx-offload off
    fi
else
    echo "Disabling offload"
    sudo ethtool -K $if1 tls-hw-tx-offload off
    sudo ethtool -K $if1 tls-hw-rx-offload off
    ssh -t $loader1 sudo ethtool -K $dif1 tls-hw-tx-offload off
    ssh -t $loader1 sudo ethtool -K $dif1 tls-hw-rx-offload off
fi

# For tcp avoid using ktls flags
if [ $TYPE == 0 ]; then
    echo "Running TCP"
    TLSFLAGS_SERVER=""
    TLSFLAGS_CLIENT=""
else
    echo "Running TLS"
    TLSFLAGS_SERVER="--ktls"
    TLSFLAGS_CLIENT="--tls --ktls --ktls_record_size=$RECSIZE"
fi

mkdir $OUTPUT
sudo pkill -x iperf
ssh $loader1 pkill -x iperf
#sudo dmesg -C

if [ `hostname` == "gen-l-vrt-010.mtl.labs.mlnx" ]; then
    LCORES=( 0 0 0 0 0 0 )
    RCORES=( 0 1 2 6 7 8 )
elif [ `hostname` == "dante732" ]; then
    LCORES=( 0 0 0 0 0 0 )
    RCORES=( 0 2 4 6 8 10 )
else
    echo unknown hostname: `hostname`
    echo modify $0 to add local and remote cores
    exit
fi

# Start server
echo "[+] Running iperf server..."
if [ $ISENC == 1 ]; then
    for i in `seq 1 $THREADS`;
    do
        echo ssh -t $loader1 \"cd $IPERF\; LD_LIBRARY_PATH=$OPENSSL taskset -c ${RCORES[$i]} $IPERF/src/iperf -s -X -P $PARALLEL -p $[$PORT + $i]\"
        ssh -t $loader1 "cd $IPERF; LD_LIBRARY_PATH=$OPENSSL taskset -c ${RCORES[$i]} $IPERF/src/iperf -s -X -P $PARALLEL -p $[$PORT + $i]" > /dev/null &
    done
    ssh -t $loader1 "echo $DROP | sudo tee /sys/module/mlx5_core/parameters/mlx5_drop_prob"
    ssh -t $dip1 sudo ethtool -K $dif1 gso on
    ssh -t $dip1 sudo ethtool -K $dif1 tso on
    ssh -t $dip1 sudo tc qdisc del dev $dif1 root
    #ssh -t $dip1 sudo tc qdisc add dev $dif1 root handle 1:0 fq maxrate 400Mbit
    sudo tc qdisc del dev $if1 root
    #sudo tc qdisc add dev $if1 root handle 1:0 fq maxrate 400Mbit
else
    for i in `seq 1 $THREADS`;
    do
        echo LD_LIBRARY_PATH=$OPENSSL taskset -c ${LCORES[$i]} $IPERF/src/iperf -s -P $PARALLEL -p $[$PORT + $i] $TLSFLAGS_SERVER 
        LD_LIBRARY_PATH=$OPENSSL taskset -c ${LCORES[$i]} $IPERF/src/iperf -s -l $MSGSIZE -P $PARALLEL -p $[$PORT + $i] $TLSFLAGS_SERVER > /dev/null &
    done
	sleep $[$TIME+$RAMP] && sudo pkill -x iperf &
    ssh -t $dip1 sudo ethtool -K $dif1 gso off
    ssh -t $dip1 sudo ethtool -K $dif1 tso off
    ssh -t $dip1 sudo ethtool -K $dif1 tls-hw-tx-offload off
    ssh -t $dip1 sudo ethtool -K $dif1 tls-hw-rx-offload off
    ssh -t $dip1 sudo tc qdisc del dev $dif1 root
    if [ $DROP != 0 ]; then
	#ssh -t $loader1 "echo $DROP | sudo tee /sys/module/mlx5_core/parameters/mlx5_tx_drop_prob"
         ssh -t $dip1 sudo tc qdisc add dev $dif1 root handle 1: netem loss random `python -c "print 1.0 / $DROP * 100"`% # delay 5ms
         ssh -t $dip1 sudo tc qdisc add dev $dif1 parent 1:1 pfifo limit 1000
        #ssh -t $dip1 sudo tc qdisc add dev $dif1 root handle 1: netem loss `python -c "print 1.0 / $DROP * 100"`% reorder `python -c "print 1.0 / $DROP * 100"`% delay 1ms
          #ssh -t $dip1 sudo tc qdisc add dev $dif1 root handle 1: netem loss `python -c "print 1.0 / $DROP * 100"`% reorder 1% delay 1ms
          #ssh -t $dip1 sudo tc qdisc add dev $dif1 parent 1:1 pfifo limit 1000
    else
	#ssh -t $loader1 "echo $DROP | sudo tee /sys/module/mlx5_core/parameters/mlx5_tx_drop_prob"
         ssh -t $dip1 sudo tc qdisc add dev $dif1 root handle 1: netem loss random 0% # delay 5ms
         ssh -t $dip1 sudo tc qdisc add dev $dif1 parent 1:1 pfifo limit 1000
          #ssh -t $dip1 sudo tc qdisc add dev $dif1 root handle 1: netem loss 0% reorder 0% delay 1ms
          #ssh -t $dip1 sudo tc qdisc add dev $dif1 parent 1:1 pfifo limit 1000
        #ssh -t $dip1 sudo tc qdisc add dev $dif1 root handle 1: netem reorder 0%
    fi
fi

sleep $RAMP

echo "[+] Running iperf client..."
if [ $ISENC == 1 ]; then
    for i in `seq 1 $THREADS`;
    do 
        echo "LD_LIBRARY_PATH=$OPENSSL taskset -c ${LCORES[$i]} $IPERF/src/iperf -c $dip1 -P $PARALLEL -p $[$PORT + $i] -l $MSGSIZE -t $[$TIME] $TLSFLAGS_CLIENT | tee -a $OUTPUT/iperf.txt &"
        LD_LIBRARY_PATH=$OPENSSL taskset -c ${LCORES[$i]} $IPERF/src/iperf -c $dip1 -P $PARALLEL -p $[$PORT + $i] -l $MSGSIZE -t $[$TIME] $TLSFLAGS_CLIENT | tee -a $OUTPUT/iperf.txt &
    done
else
    for i in `seq 1 $THREADS`;
    do 
        echo ssh $loader1 \"cd $IPERF\; LD_LIBRARY_PATH=$OPENSSL taskset -c ${RCORES[$i]} $IPERF/src/iperf -c $ip1 -P $PARALLEL -p $[$PORT + $i] -l $MSGSIZE -t $[$TIME] $TLSFLAGS_CLIENT\"
        ssh $loader1 "cd $IPERF; LD_LIBRARY_PATH=$OPENSSL taskset -c ${RCORES[$i]} $IPERF/src/iperf -c $ip1 -P $PARALLEL -p $[$PORT + $i] -l $MSGSIZE -t $[$TIME] $TLSFLAGS_CLIENT" | tee -a $OUTPUT/iperf.txt &
    done
fi
