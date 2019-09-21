#!/bin/bash

perf=/homes/borispi/linux/tools/perf/perf
nvme1=`ls -l /dev/nvme*n1 | awk '{print  $10}' | awk -F/ '{print $3}'`

# remote zerocopy
[ -z "$ZEROCOPYR" ] && echo 'Using copy' && ZEROCOPYR=0
# local zerocopy
[ -z "$ZEROCOPYL" ] && echo 'Using copy' && ZEROCOPYL=0
# local zerocrc
[ -z "$ZEROCRCL" ] && echo 'Using crc' && ZEROCRCL=0
[ -z "$dip1" ] && echo 'no dip2' && exit;
[ -z "$TIME" ] && TIME=60
[ -z "$OUTPUT" ] && OUTPUT=/tmp/
[ -z "$FILE" ] && echo 'Using /dev/$nvme1' && FILE=/dev/$nvme1
[ -z "$RW" ] && RW=randread
[ -z "$IODEPTH" ] && IODEPTH=128
[ -z "$NUMJOBS" ] && NUMJOBS=1
[ -z "$BLOCKSIZE" ] && BLOCKSIZE=4k
[ -z "$RAMP" ] && RAMP=30
[ -z "$WAIT" ] && WAIT=false

echo "Connecting $dip1.."
echo Using /dev/$nvme1

export DIRECT=1
export JOB=$TBASE/Tests/fio/random-io-template.fio

export RUNTIME=$TIME
export OUTPUT=$OUTPUT
export FILE=$FILE
export RW=$RW
export IODEPTH=$IODEPTH
export NUMJOBS=$NUMJOBS
export BLOCKSIZE=$BLOCKSIZE
export NAME=$RW-$IODEPTH-$NUMJOBS-$BLOCKSIZE-$ZEROCOPYL-$ZEROCRCL

mkdir $OUTPUT
sudo pkill -x fio
#sudo dmesg -C

#remote zcopy
[ $ZEROCOPYR == 0 ] && echo 'Set copy..' && ssh $dip1 "echo 0 | sudo tee /sys/module/nvmet_tcp/parameters/nvmeotcp_zerocopy"
[ $ZEROCOPYR == 1 ] && echo 'Set zerocopy' && ssh $dip1 "echo 1 | sudo tee /sys/module/nvmet_tcp/parameters/nvmeotcp_zerocopy"

# local zcopy
echo $ZEROCOPYL | sudo tee /sys/module/nvme_tcp/parameters/nvmeotcp_zerocopy
echo $ZEROCRCL | sudo tee /sys/module/nvme_tcp/parameters/nvmeotcp_zerocrc

sync
echo 3 | sudo tee /proc/sys/vm/drop_caches
MYPWD=`pwd`
echo "=== $FILE ============================================"
echo "Running benchmark $RW with I/O depth of $IODEPTH numjobs $NUMJOBS blocksize $BLOCKSIZE zerocopy $ZEROCOPYL"
cd $OUTPUT
echo "fio $JOB"
echo Running $RW depth $IODEPTH jobs $NUMJOBS size $BLOCKSIZE zc $ZEROCOPYL remote zc $ZEROCOPYR  zcrc $ZEROCRCL | sudo tee /dev/kmsg
#echo 1 | sudo tee /sys/module/nvme_core/parameters/trace
# $RW-$IODEPTH-$NUMJOBS-$BLOCKSIZE-$ZEROCOPYL-$ZEROCOPYR.terse
#$perf stat -a -C 0 -e ref-cycles,instructions,cache-misses,msr/tsc -x, -o $OUTPUT/perf_stat.txt fio $JOB --output-format=terse | tee $OUTPUT/fio.terse &
echo "sudo -E $perf stat -D $[$RAMP*1000] -a -C 0 -e duration_time,task-clock,cycles,instructions,cache-misses x, -o $OUTPUT/perf_stat.txt --append sudo -E DIRECT=$DIRECT RW=$RW FILE=$FILE IODEPTH=$IODEPTH NUMJOBS=$NUMJOBS NAME=$NAME BLOCKSIZE=$BLOCKSIZE OUTPUT=$OUTPUT RUNTIME=$RUNTIME fio $JOB --ramp_time=$RAMP --output-format=terse --terse-version=2 | tee -a $OUTPUT/fio.terse &"
sudo -E $perf stat -D $[$RAMP*1000] -a -C 0 -e duration_time,task-clock,cycles,instructions,cache-misses -x, -o $OUTPUT/perf_stat.txt --append sudo -E fio $JOB --ramp_time=$RAMP --output-format=terse --terse-version=2 | tee -a $OUTPUT/fio.terse &
test_pid=$!

if ! [ "$WAIT" == true ]; then
	echo 'waiting for fio'
	wait $test_pid
fi
#echo 0 | sudo tee /sys/module/nvme_core/parameters/trace
# flush the trace log from aio,nvme,rx_action by running fio which triggers the dmesg writes
#sudo dd if=$FILE of=/scrap/borisp/tmp/bla bs=4k count=1
dmesg | tail -n 90 | tee -a $OUTPUT/dmesg_nvme_trace.txt
cd $MYPWD
