#!/bin/bash

TBASE=$TBASE/TestSuite
T=$TBASE/Tests/ssl/iperf_tx

base=$1
[ -z $base ] && echo 'Usage: $0 <base>' && exit 0

$TBASE/Process/parse.py $base
name=$1/setup.csv
fname=$1/filter.csv
model=$T/model

$T/filter.py $name > $fname

$T/post.py $fname $model.csv 

head -n 1 $model.csv      > $model.tx.csv
head -n 1 $model.csv      > $model.rx.csv
grep "\-0\-1" $model.csv   | grep -v 1024  >> $model.tx.csv
grep "\-0\-0" $model.csv   | grep -v 1024  >> $model.rx.csv

gnuplot $T/breakdown.plot
