#!/bin/bash

cd `dirname $0`

[ -z "$DATE" ] && DATE=`date +"%y_%m_%d_%H.%M.%S"`
[ -z "$REPEAT" ] && REPEAT=5

TBASE=$TBASE/TestSuite/
[ ! -e "$TBASE" ] && echo "base directory is not at $TBASE" && exit -1
RBASE=$TBASE/Results
Test=$TBASE/Tests/nginx

source $TBASE/Conf/config_`hostname`.sh
$TBASE/Conf/setup.sh

OUT_FILE=$RBASE/$DATE

echo "source $Test/config.sh"
source $Test/config.sh | tee $OUT_FILE/test_raw.txt
export NOCONFIG=1

# Total runtime lower limit:
# repeat x cores x fsize x offload x test_time = 5 * 2 * 5 * 2 * 1 = 100min

export ZEROREQL=( 1 0 )
export CORESL=( 1 8 )
#export CONNSL=( 2000 4000 6000 8000 10000 )
export CONNSL=( 128 )
export FSIZES=( 4096 16384 65536 262144 1048576 )
#export FSIZES=( 65536 )
# 2GB / 4KB = 512K

for fsizel in ${FSIZES[@]};
do
	export FSIZE=$fsizel
	#echo "[+] fetching all inodes for $TBASE/nvme/mount/nginx.$fsizel"
	#time ls $TBASE/nvme/mount/nginx.$FSIZE > /dev/null # fetch all inodes
	#export MAX_MEM=2147483648
	#$Test/generate_files.sh
	for zreql in ${ZEROREQL[@]};
	do
		export ZCOPY=$zreql
		export ZCRC=$zreql
		for coresl in ${CORESL[@]};
		do
			export CORES=$coresl
			for connsl in ${CONNSL[@]};
			do
				export CONNS=$connsl
				export OUT_FILE=$RBASE/$DATE/`basename $Test`-$zreql-$coresl-$connsl-$fsizel
				export repeat=$REPEAT
				mkdir -p $OUT_FILE
				echo "running $Test zerorqq $ZC=$ZCRC+$ZCOPY cores $coresl conns $connsl fsize $fsizel"
				./run_test.sh $Test
			done
		done
	done
done
