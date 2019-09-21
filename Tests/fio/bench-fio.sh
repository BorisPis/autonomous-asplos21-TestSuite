#!/bin/bash

[ -z "$ZEROCOPY" ] && echo 'Using copy' && ZEROCOPY=0
[ -z "$dip2" ] && echo 'no dip2' && exit;
[ -z "$TIME" ] && TIME=60
[ -z "$FILE" ] && echo 'Using /dev/nvme0n1' && FILE=/dev/nvme0n1
[ -z "$OUTPUT" ] && OUTPUT=/tmp/

echo "Connecting $dip2.."

export DIRECT=1
export JOB=$TBASE/TestSuite/Tests/fio/random-io-template.fio

export RUNTIME=$TIME
export OUTPUT=$OUTPUT
export FILE=$FILE

mkdir $OUTPUT
#sudo dmesg -C

#remote zcopy
[ $ZEROCOPY == 0 ] && echo 'Set copy..' && ssh $ip2 "echo 0 | sudo tee /sys/module/nvmet_tcp/parameters/nvmeotcp_zerocopy"
[ $ZEROCOPY == 1 ] && echo 'Set zerocopy' && ssh $ip2 "echo 1 | sudo tee /sys/module/nvmet_tcp/parameters/nvmeotcp_zerocopy"

# local zcopy
echo $ZEROCOPY | sudo tee /sys/module/nvme_tcp/parameters/nvmeotcp_zerocopy

for x in randread
#for x in randread randwrite read write
do
	#for y in 1 16 512
	for y in 64
	#for y in 64 8192
	do
		#for z in 1 2 4 8 16 32
		#for z in 1 32
		for z in 1
		do
            		#for s in 4k 8k 16k 32k 64k 128k 256k 512k 1m
            		for s in 4k 128k
            		do 
            		    #sudo dmesg -C
            		    sync
            		    echo 3 > /proc/sys/vm/drop_caches
            		    MYPWD=`pwd`
            		    echo "=== $FILE ============================================"
            		    echo "Running benchmark $x with I/O depth of $y numjobs $z blocksize $s zerocopy $ZEROCOPY"
            		    cd $OUTPUT
            		    export BLOCKSIZE=$s
            		    export RW=$x
            		    export IODEPTH=$y
            		    export NUMJOBS=$z
            		    echo "fio $JOB"
            		    export NAME=$x-$y-$z-$s-$ZEROCOPY
            		    echo Running $x depth $y jobs $z size $s zc $ZEROCOPY | sudo tee /dev/kmsg
            		    #echo 1 | sudo tee /sys/module/nvme_core/parameters/trace
            		    perf stat -a -C 0 -o $OUTPUT/$x-$y-$z-$s-ZEROCOPY.perf fio $JOB --output-format=terse | tee $OUTPUT/$x-$y-$z-$s-$ZEROCOPY.terse &
            		    test_pid=$!

            		    wait $test_pid
            		    #echo 0 | sudo tee /sys/module/nvme_core/parameters/trace
            		    # flush the trace log from aio,nvme,rx_action by running fio which triggers the dmesg writes
            		    #sudo dd if=$FILE of=/scrap/borisp/tmp/bla bs=4k count=1
            		    dmesg | tail -n 24 | tee $OUTPUT/$x-$y-$z-$s-$ZEROCOPY.dmesg
            		    cd $MYPWD
            		done
		done
	done
done
