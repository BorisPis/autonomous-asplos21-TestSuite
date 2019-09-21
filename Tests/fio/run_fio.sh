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
echo "source $Test/config.sh"
source $Test/config.sh >> $OUT_FILE/test_raw.txt
export NOCONFIG=1 # skip config on each test

# Total runtime lower limit:
# trace x repeat x depth x size x offload x test_time = 2 * 5 * 4 * 14 * 1 = 560min (4hrs)

#export ZEROCRCLL=( 0 1 )
export ZEROCRCLL=( 0 )
#export ZEROCOPYLL=( 0 1 )
export ZEROCOPYLL=( 0 )
#export BLOCKSIZEL=( 4K 16K 64K 256K 1024K )
export BLOCKSIZEL=( 4K 16K 64K 256K 1024K )
#export BLOCKSIZEL=( 4K )
export IODEPTHL=( 1 2 4 8 16 32 64 128 256 512 1024 2048 4096 8192 )
#export IODEPTHL=( 128 8192 )
Test=$TBASE/Tests/fio

TRACEL=( 1 0 )

for zcrcl in ${ZEROCRCLL[@]};
do
	export ZEROCRCL=$zcrcl
	for zcl in ${ZEROCOPYLL[@]};
	do
		export ZEROCOPYL=$zcl
		for bs in ${BLOCKSIZEL[@]};
		do
			export BLOCKSIZE=$bs
			for depth in ${IODEPTHL[@]};
			do 
				for trace in ${TRACEL[@]};
				do 
					export TRACE=$trace
					export IODEPTH=$depth
					export OUT_FILE=$RBASE/$DATE/`basename $Test`-$bs-$depth-$zcrcl-$zcl-$trace
					export repeat=$REPEAT
					mkdir -p $OUT_FILE
					echo "running $Test $zcrcl ZEROCRCL $zcl ZEROCOPYL $bs BLOCKSIZE $depth IODEPTH $trace TRACE"
					./run_test.sh $Test
				done
			done
		done
	done
done
