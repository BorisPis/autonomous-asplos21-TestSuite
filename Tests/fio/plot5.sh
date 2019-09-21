#!/bin/bash

TBASE=$TBASE/TestSuite

base=$1
[ -z $base ] && echo 'Usage: $0 <base>' && exit 0

$TBASE/Process/parse.py $base
name=$1/setup.csv
fname=$1/filter.csv
post=$TBASE/Tests/fio/post.csv
plot=$TBASE/Tests/fio/post.plot
breakdown=$TBASE/Tests/fio/breakdown
model2=$TBASE/Tests/fio/model2
model_lat=$TBASE/Tests/fio/model.lat
model2_plot=$TBASE/Tests/fio/breakdown_crc2.plot
breakdown_c=$TBASE/Tests/fio/breakdown2

$TBASE/Tests/fio/filter.py $name > $fname
head -n 1 $fname > $fname.1
grep -i -E "\-4k-|\-16k-|\-64k-|\-256k-|\-1024k-" $fname >> $fname.1
$TBASE/Tests/fio/post3.py $fname.1 $model2.csv 

# 4K
echo -n '#' > $breakdown_c.4k.csv
cat $model2.csv | head -n 1 >> $breakdown_c.4k.csv
sort -nk12  -s $model2.csv | grep -i "\-4k-" >> $breakdown_c.4k.csv
# 16K
echo -n '#' > $breakdown_c.16k.csv
cat $model2.csv | head -n 1 >> $breakdown_c.16k.csv
sort -nk12 -s $model2.csv | grep -i "\-16k-" >> $breakdown_c.16k.csv 
# 64K
echo -n '#' > $breakdown_c.64k.csv
cat $model2.csv | head -n 1 >> $breakdown_c.64k.csv
sort -nk12 -s $model2.csv | grep -i "\-64k-" >> $breakdown_c.64k.csv 
# 256K
echo -n '#' > $breakdown_c.256k.csv
cat $model2.csv | head -n 1 >> $breakdown_c.256k.csv
sort -nk12 -s $model2.csv | grep -i "\-256k-" >> $breakdown_c.256k.csv 
# 1024K
echo -n '#' > $breakdown_c.1024k.csv
cat $model2.csv | head -n 1 >> $breakdown_c.1024k.csv
sort -nk12 -s $model2.csv | grep -i "\-1024k-" >> $breakdown_c.1024k.csv 

#gnuplot breakdown_crc2.plot
#gnuplot breakdown_crc3.plot
#gnuplot breakdown_crc3_wide2.plot
gnuplot breakdown.gp
