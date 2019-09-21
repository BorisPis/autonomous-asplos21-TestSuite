#!/bin/bash

NAME=$1
[ -z $NAME ] && echo 'Missing results file' && exit

grep "cycles" $NAME/perf_stat.txt
#   286,480,974,542      cycles                    # 3152750.443 GHz

grep "copy    0" $NAME/result.txt
# nvme_tcp: copy    0          1083853      18399591173  468453746005751               60           125146
