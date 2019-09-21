#!/bin/bash

nvme1=`ls -l /dev/nvme*n1 | awk '{print  $10}' | awk -F/ '{print $3}'`
[ -z "$ZEROCOPYL" ] && echo 'Using copy' && ZEROCOPYL=0
[ -z "$ZEROCRCL" ] && echo 'Using crc' && ZEROCRCL=0
[ -z "$dip2" ] && echo 'no dip2' && exit;
[ -z "$TIME" ] && TIME=60
[ -z "$OUTPUT" ] && OUTPUT=/tmp/
[ -z "$FILE" ] && echo 'Using /dev/nvme0n1' && FILE=/dev/$nvme1
[ -z "$RW" ] && RW=randread
[ -z "$IODEPTH" ] && IODEPTH=128
[ -z "$NUMJOBS" ] && NUMJOBS=1
[ -z "$BLOCKSIZE" ] && BLOCKSIZE=4k
[ -z "$WAIT" ] && WAIT=false
[ -z "$RAMP" ] && RAMP=0

RAMP=$RAMP ZEROCOPYL=$ZEROCOPYL ZEROCRCL=$ZEROCRCL WAIT=true TIME=$TIME FILE=$FILE OUTPUT=$OUTPUT RW=$RW IODEPTH=$IODEPTH NUMJOBS=$NUMJOBS BLOCKSIZE=$BLOCKSIZE $TBASE/Tests/fio/test.sh

