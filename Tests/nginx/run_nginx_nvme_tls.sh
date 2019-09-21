#!/bin/bash

cd `dirname $0`

[ -z "$DATE" ] && DATE=`date +"%y_%m_%d_%H.%M.%S"`
[ -z "$REPEAT" ] && REPEAT=5


TBASE=$TBASE/TestSuite/
RBASE=$TBASE/Results
[ ! -e "$TBASE" ] && echo "base directory is not at $TBASE" && exit -1
source $TBASE/Conf/config_`hostname`.sh
$TBASE/Conf/setup.sh

# Total runtime lower limit:
# repeat x cores x fsize x offload x test_time = 5 * 2 * 5 * 2 * 1.1 = 110min

export NVMETLS=1

############
# We are only interested in all offload or no-offload cases:
###########
ALL_OFFLOADL=( 1 0 )

#export CORESL=( 8 1 )
export CORESL=( 1 8 )
export CONNSL=( 128 )
export FSIZES=( 16384 65536 262144 1048576 4096 )
export MODE=https # can be reverted by offlod=3
Test=$TBASE/Tests/nginx

#$TBASE/Tests/nginx/drop_periodic.sh > /dev/null &
for all_offload in ${ALL_OFFLOADL[@]};
do
  if [ $all_offload == 0 ]; then
	  echo "[+] all offload"
	  nvmetlso=0;
	  offload=0;
	  zreql=0;
  else
	  echo "[-] no offload"
	  nvmetlso=1;
	  offload=2;
	  zreql=1;
  fi
  export NVMETLS_OFFLOAD=$nvmetlso
  export OFFLOAD=$offload
  export ZCOPY=$zreql
  export ZCRC=$zreql
 
  # config must run once for nvme-tls offload and again for non-offload
  OUT_FILE=$RBASE/$DATE
  echo "source $Test/config.sh"
  source $Test/config.sh >> $OUT_FILE/test_raw.txt
  export NOCONFIG=1

      for fsizel in ${FSIZES[@]};
      do
        export FSIZE=$fsizel
	sudo ls $TBASE/nvme/mount/nginx.$fsizel > /dev/null # fetch all inodes
        for coresl in ${CORESL[@]};
        do
          export CORES=$coresl
          for connsl in ${CONNSL[@]};
          do
            export CONNS=$connsl
            export OUT_FILE=$RBASE/$DATE/`basename $Test`-$zreql-$coresl-$connsl-$fsizel-$offload-$nvmetlso
	    export repeat=$REPEAT
            mkdir -p $OUT_FILE
            echo "running $Test zero $ZC cores $coresl conns $connsl fsize $fsizel offload $offload nvmetls-offload $nvmetlso"
            ./run_test.sh $Test
          done
        done
      done
done
