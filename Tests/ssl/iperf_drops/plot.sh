#!/bin/bash

TBASE=$TBASE/TestSuite
T=$TBASE/TestSuite/Tests/ssl/iperf_drops

base=$1
[ -z $base ] && echo 'Usage: $0 <base>' && exit 0

$TBASE/Process/parse.py $base
name=$1/setup.csv
fname=$1/filter.csv
model=$T/model

$T/filter.py $name > $fname
$T/post.py $fname $model.csv 

head -n 1 $model.csv      > $model.tcp.csv
head -n 1 $model.csv      > $model.tls.csv
head -n 1 $model.csv      > $model.tls.offload.csv
grep "drops\-0" $model.csv   >> $model.tcp.csv
grep "drops\-1" $model.csv   >> $model.tls.csv
grep "drops\-2" $model.csv   >> $model.tls.offload.csv

gnuplot $T/tx_drops2b.plot
gnuplot $T/rx_drops2b.plot
