#!/bin/bash

cd `dirname $0`

[ -z "$DATE" ] && DATE=`date +"%y_%m_%d_%H.%M.%S"`
[ -z "$REPEAT" ] && REPEAT=5


TBASE=$TBASE/TestSuite/
RBASE=$TBASE/Results
[ ! -e "$TBASE" ] && echo "base directory is not at $TBASE" && exit -1
source $TBASE/Conf/config_`hostname`.sh
$TBASE/Conf/setup.sh

OUT_FILE=$RBASE/$DATE
export NOCGROUP=1
echo "source $Test/config.sh"
source $Test/config.sh >> $OUT_FILE/test_raw.txt
export NOCONFIG=1

# Total runtime lower limit:
# repeat x cores x fsize x offload x test_time = 5 * 2 * 4 * 4 * 1 = 160min

#export ZEROREQL=( 0 1 )
# 0: openssl, 1: ktls-offload, 2: ktls-offload-zc, 3:http-plaintext
export TLS_OFFLOADL=( 0 1 2 3 )
export ZEROREQL=( 0 )
#export CORESL=( 1 2 4 )
#export CORESL=( 1 8 )
export CORESL=( 1 8 )
#export CONNSL=( 2000 4000 6000 8000 10000 )
export CONNSL=( 128 )
export FSIZES=( 4096 16384 65536 262144 1048576 )
export MODE=https # can be reverted by offlod=3
# 2GB / 4KB = 512K
Test=$TBASE/Tests/nginx

for offload in ${TLS_OFFLOADL[@]};
do
  export OFFLOAD=$offload
  for fsizel in ${FSIZES[@]};
  do
    export FSIZE=$fsizel
    #export MAX_MEM=2147483648
    #$Test/generate_files.sh
    for zreql in ${ZEROREQL[@]};
    do
      export ZC=$zreql
      for coresl in ${CORESL[@]};
      do
        export CORES=$coresl
        for connsl in ${CONNSL[@]};
        do
          export CONNS=$connsl
          export OUT_FILE=$RBASE/$DATE/`basename $Test`-$zreql-$coresl-$connsl-$fsizel-$offload
	  export repeat=$REPEAT
          mkdir -p $OUT_FILE
          echo "running $Test zero $ZC cores $coresl conns $connsl fsize $fsizel offload $offload"
          ./run_test.sh $Test
        done
      done
    done
  done
done
