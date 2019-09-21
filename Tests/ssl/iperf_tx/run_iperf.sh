#!/bin/bash

cd `dirname $0`

[ -z "$DATE" ] && DATE=`date +"%y_%m_%d_%H.%M.%S"`
[ -z "$REPEAT" ] && REPEAT=10

TBASE=$TBASE/TestSuite/
RBASE=$TBASE/Results
[ ! -e "$TBASE" ] && echo "base directory is not at $TBASE" && exit -1
source $TBASE/Conf/config_`hostname`.sh
$TBASE/Conf/setup.sh

OFFLOADL=( 0 )
RECSIZEL=( 2048 4096 8192 16384 )
TRACEL=( 1 0 )
ISENCL=( 1 0 )
# TODO: Multiple threads requires additional output processing features
export THREADS=1

Test=$TBASE/Tests/ssl/iperf_tx

for offload in ${OFFLOADL[@]};
do
	export OFFLOAD=$offload
	for isenc in ${ISENCL[@]};
	do
		export ISENC=$isenc
		for recsz in ${RECSIZEL[@]};
		do
			export RECSIZE=$recsz
			for trace in ${TRACEL[@]};
			do 
				export TRACE=$trace
				export OUT_FILE=$RBASE/$DATE/`basename $Test`-$recsz-$trace-$isenc-$offload
				export repeat=$REPEAT
				mkdir -p $OUT_FILE
				echo "running $Test $recsz RECSZ $trace TRACE $isenc ISENC $offload OFFLOAD"
				$Test/run_test.sh $Test
			done
		done
	done
done
