#!/bin/bash

cd `dirname $0`

[ -z "$DATE" ] && DATE=`date +"%y_%m_%d_%H.%M.%S"`


TBASE=$TBASE/TestSuite/
RBASE=$TBASE/Results
[ ! -e "$TBASE" ] && echo "base directory is not at $TBASE" && exit -1
source $TBASE/Conf/config_`hostname`.sh
$TBASE/Conf/setup.sh

ALL_OFFLOADL=( 3 2 1 0 )
#export ZEROCRCLL=( 0 1 )
#export ZEROCOPYLL=( 0 1 )
#export ZEROCOPYLL=( 0 1 )
#export BLOCKSIZEL=( 64K )
#export BLOCKSIZEL=( 4K 16K 64K 256K )
export BLOCKSIZEL=( 4K 16K 64K 256K )
export NVMETLS=1
Test=$TBASE/Tests/fio
depth=1
trace=0

for all_offload in ${ALL_OFFLOADL[@]};
do
  case $all_offload in
    0)
      echo [-] no offload;
      nvmetlso=0;
      zcl=0;
      zcrcl=0;
      ;;
    1)
      echo [+] tls offload enabled;
      nvmetlso=1;
      zcl=0;
      zcrcl=0;
      ;;
    2)
      echo [+] zcopy tls offload enabled;
      nvmetlso=1;
      zcl=1;
      zcrcl=0;
      ;;
    3)
      echo [+] crc zcopy tls offload enabled;
      nvmetlso=1;
      zcl=1;
      zcrcl=1;
      ;;
  esac

  export NVMETLS_OFFLOAD=$nvmetlso
  export ZEROCRCL=$zcrcl
  export ZEROCOPYL=$zcl
  for bs in ${BLOCKSIZEL[@]};
  do
    export BLOCKSIZE=$bs
    export TRACE=0
    export IODEPTH=1
    export OUT_FILE=$RBASE/$DATE/`basename $Test`-$bs-$depth-$zcrcl-$zcl-$trace-$nvmetlso
    export repeat=1
    mkdir -p $OUT_FILE
    echo "running $Test $zcrcl ZEROCRCL $zcl ZEROCOPYL $bs BLOCKSIZE $depth IODEPTH $trace TRACE $nvmetlso NVMETLS"
    ./run_test.sh $Test
  done
done
