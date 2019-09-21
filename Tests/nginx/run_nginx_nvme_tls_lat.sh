#!/bin/bash

cd `dirname $0`

[ -z "$DATE" ] && DATE=`date +"%y_%m_%d_%H.%M.%S"`
[ -z "$REPEAT" ] && REPEAT=5

TBASE=$TBASE/TestSuite/
RBASE=$TBASE/Results
[ ! -e "$TBASE" ] && echo "base directory is not at $TBASE" && exit -1
source $TBASE/Conf/config_`hostname`.sh
$TBASE/Conf/setup.sh

export NVMETLS=1
## 0: no tls rx offload, 1: tls rx offload
#export NVMETLS_OFFLOADL=( 0 1 )
## 0: openssl, 1: ktls-offload, 2: ktls-offload-zc, 3:http-plaintext
#export TLS_OFFLOADL=( 0 1 2 3 )
#export TLS_OFFLOADL=( 0 2 )
#export ZEROREQL=( 0 1 )

ALL_OFFLOADL=( 0 1 2 3 )

export CORESL=( 1 )
export CONNSL=( 1 )
export FSIZES=( 16384 65536 262144 1048576 4096 )
export MODE=https # can be reverted by offlod=3
export THREADS=1
Test=$TBASE/Tests/nginx

#$TBASE/Tests/nginx/drop_periodic.sh > /dev/null &
for all_offload in ${ALL_OFFLOADL[@]};
do
  case $all_offload in
    0)
      echo no offload;
      nvmetlso=0;
      offload=0;
      zcopy=0;
      zcrc=0;
      ;;
  1)
      echo offload tls;
      nvmetlso=1;
      offload=2;
      zcopy=0;
      zcrc=0;
      ;;
  2)
      echo offload tls + copy;
      nvmetlso=1;
      offload=2;
      zcopy=1;
      zcrc=0;
      ;;
  3)
      echo offload tls + copy + crc;
      nvmetlso=1;
      offload=2;
      zcopy=1;
      zcrc=1;
      ;;
  esac
  export NVMETLS_OFFLOAD=$nvmetlso
  export OFFLOAD=$offload
  export ZC=0 # do not skip both
  export ZCRC=$zcrc
  export ZCOPY=$zcopy
      for fsizel in ${FSIZES[@]};
      do
        export FSIZE=$fsizel
        for coresl in ${CORESL[@]};
        do
          export CORES=$coresl
          for connsl in ${CONNSL[@]};
          do
            export CONNS=$connsl
            export OUT_FILE=$RBASE/$DATE/`basename $Test`-$zreql-$coresl-$connsl-$fsizel-$offload-$nvmetlso-$zcopy-$zcrc
	    export repeat=$REPEAT
            mkdir -p $OUT_FILE
            echo "running $Test zero $ZC cores $coresl conns $connsl fsize $fsizel offload $offload nvmetls-offload $nvmetlso copy $ZCOPY crc $ZCRC"
            ./run_test.sh $Test
          done
        done
      done
done
