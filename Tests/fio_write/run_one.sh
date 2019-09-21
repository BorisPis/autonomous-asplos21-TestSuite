#!/bin/bash

[ -z "$ZEROCOPYL" ] && echo 'Using copy' && ZEROCOPYL=0
[ -z "$ZEROCRCL" ] && echo 'Using crc' && ZEROCRCL=0
[ -z "$dip1" ] && echo 'no dip1' && exit;
[ -z "$TIME" ] && TIME=60
[ -z "$OUTPUT" ] && OUTPUT=/tmp/
[ -z "$FILE" ] && echo 'Using /dev/nvme0n1' && FILE=/dev/nvme0n1
[ -z "$RW" ] && RW=randwrite
[ -z "$IODEPTH" ] && IODEPTH=128
[ -z "$NUMJOBS" ] && NUMJOBS=2
[ -z "$BLOCKSIZE" ] && BLOCKSIZE=4k
[ -z "$WAIT" ] && WAIT=false
[ -z "$RAMP" ] && RAMP=0

FILE=$FILE RAMP=$RAMP ZEROCOPYL=$ZEROCOPYL ZEROCRCL=$ZEROCRCL WAIT=true TIME=$TIME OUTPUT=$OUTPUT RW=$RW IODEPTH=$IODEPTH NUMJOBS=$NUMJOBS BLOCKSIZE=$BLOCKSIZE $TBASE/Tests/fio_write/test.sh
