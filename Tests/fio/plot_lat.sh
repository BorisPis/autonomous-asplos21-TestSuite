#!/bin/bash

TBASE=/homes/borispi/bTestSuite

base=$1
[ -z $base ] && echo 'Usage: $0 <base>' && exit 0

$TBASE/Process/parse.py $base
name=$1/setup.csv
fname=$1/filter.csv

fname_lat=$1/filter.lat.csv
post_lat=$TBASE/Tests/fio/post.lat.csv

$TBASE/Tests/fio/filter_lat.py $name > $fname_lat
$TBASE/Tests/fio/post_process_lat.py $fname_lat $model_lat.csv 
