#!/bin/bash

TBASE=/homes/borispi/bTestSuite

base=$1
[ -z $base ] && echo 'Usage: $0 <base>' && exit 0

$TBASE/Process/parse.py $base
name=$1/setup.csv
fname=$1/filter.csv
post=$TBASE/Tests/fio_write/post.csv
plot=$TBASE/Tests/fio_write/post.plot
breakdown=$TBASE/Tests/fio_write/breakdown
model=$TBASE/Tests/fio_write/model
model_plot=$TBASE/Tests/fio_write/breakdown_crc2.plot
breakdown_c=$TBASE/Tests/fio_write/breakdown2

$TBASE/Tests/fio_write/filter.py $name > $fname
head -n 1 $fname > $fname.1
grep -i -E "\-4k-|\-16k-|\-64k-|\-256k-|\-1m-|\-4m-" $fname >> $fname.1

$TBASE/Tests/fio_write/post.py $fname.1 $model.csv 

# 4K
echo -n '#' > $breakdown_c.4k.csv
cat $model.csv | head -n 1 >> $breakdown_c.4k.csv
sort -r -nk8  -s $model.csv | grep -i "\-4k-" >> $breakdown_c.4k.csv
# 16K
echo -n '#' > $breakdown_c.16k.csv
cat $model.csv | head -n 1 >> $breakdown_c.16k.csv
sort -r -nk8 -s $model.csv | grep -i "\-16k-" >> $breakdown_c.16k.csv 
# 64K
echo -n '#' > $breakdown_c.64k.csv
cat $model.csv | head -n 1 >> $breakdown_c.64k.csv
sort -r -nk8 -s $model.csv | grep -i "\-64k-" >> $breakdown_c.64k.csv 
# 256K
echo -n '#' > $breakdown_c.256k.csv
cat $model.csv | head -n 1 >> $breakdown_c.256k.csv
sort -r -nk8 -s $model.csv | grep -i "\-256k-" >> $breakdown_c.256k.csv 
# 1M
echo -n '#' > $breakdown_c.1m.csv
cat $model.csv | head -n 1 >> $breakdown_c.1m.csv
sort -r -nk8 -s $model.csv | grep -i "\-1m-" >> $breakdown_c.1m.csv 
# 4M
echo -n '#' > $breakdown_c.4m.csv
cat $model.csv | head -n 1 >> $breakdown_c.4m.csv
sort -r -nk8 -s $model.csv | grep -i "\-4m-" >> $breakdown_c.4m.csv 

gnuplot breakdown_crc2.plot
