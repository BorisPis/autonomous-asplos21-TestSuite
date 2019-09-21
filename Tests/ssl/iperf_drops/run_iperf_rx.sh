#!/bin/bash

cd `dirname $0`

[ -z "$DATE" ] && DATE=`date +"%y_%m_%d_%H.%M.%S"`
[ -z "$REPEAT" ] && REPEAT=5


TBASE=$TBASE/TestSuite/
RBASE=$TBASE/Results
[ ! -e "$TBASE" ] && echo "base directory is not at $TBASE" && exit -1
source $TBASE/Conf/config_`hostname`.sh
$TBASE/Conf/setup.sh

#DROPSL=( 0 200 100 50 33 25 20 16 14 12 10 )
# 0, 0.5, 1, 1.5, 2, 2.5, 3, 3.5, 4 4.5 5
DROPSL=( 0 200 100 67 50 40 34 28 25 22 20)
#DROPSL=( 200 100 )
# types: 0 - tcp, 1 - ktls, 2 - ktls_offload
TYPEL=( 2 0 1 )
#TYPEL=( 2 )
RECSIZEL=( 16384 )

Test=$TBASE/Tests/ssl/iperf_drops

export ISENC=0
export RECSIZE=16384
export MSGSIZE=262144
export THREADS=2
export PARALLEL=32

for recsz in ${RECSIZEL[@]};
do
    for drops in ${DROPSL[@]};
    do
        for t in ${TYPEL[@]};
        do
            export RECSIZE=$recsz
            export DROP=$drops
            export TYPE=$t
            export OUT_FILE=$RBASE/$DATE/`basename $Test`-$t-$drops-$recsz
	    export repeat=$REPEAT
            mkdir -p $OUT_FILE
            echo "running $Test $t type 1/$drops drops $recsz recsz"
            $Test/run_test.sh $Test
        done
    done
done
