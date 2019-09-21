#!/bin/bash

cd `dirname $0`

[ -z "$DATE" ] && DATE=`date +"%y_%m_%d_%H.%M.%S"`

RBASE=/homes/borispi/Results
Test=$TBASE/Tests/fio_write
[ ! -e "$TBASE" ] && echo "base directory is not at $TBASE" && exit -1
source $TBASE/Conf/config_`hostname`.sh
$TBASE/Conf/setup.sh

#export ZEROCRCLL=( 0 1 )
#export ZEROCOPYLL=( 0 1 )
#export ZEROCOPYLL=( 0 1 )
#export BLOCKSIZEL=( 64K )
#export BLOCKSIZEL=( 4K 16K 64K 256K 1M 4M )
#export IODEPTHL=( 128 1024 8192 )
export BLOCKSIZEL=( 256K )
export IODEPTHL=( 128 )

TRACEL=( 1 0 )

zcrcl=0
zcl=0
export ZEROCRCL=0
export ZEROCOPYL=0
for bs in ${BLOCKSIZEL[@]};
do
	export BLOCKSIZE=$bs
	for depth in ${IODEPTHL[@]};
	do 
		export IODEPTH=$depth
		for trace in ${TRACEL[@]};
		do 
			export TRACE=$trace
			export OUT_FILE=$RBASE/$DATE/`basename $Test`-$bs-$depth-$zcrcl-$zcl-$trace
			export repeat=1
			mkdir -p $OUT_FILE
			echo "running $Test $zcrcl ZEROCRCL $zcl ZEROCOPYL $bs BLOCKSIZE $depth IODEPTH $trace TRACE"
			$Test/run_test.sh $Test
		done
	done
done
