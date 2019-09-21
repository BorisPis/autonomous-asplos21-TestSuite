#!/bin/bash

TBASE=$TBASE/TestSuite

base=$1
[ -z $base ] && echo 'Usage: $0 <base>' && exit 0

$TBASE/Process/parse.py $base
name=$1/setup.csv
fname=$1/filter.csv
result=$TBASE/Tests/nginx/result

$TBASE/Tests/nginx/filter.py $name > $fname

$TBASE/Tests/nginx/post.py $fname $result.csv 
$TBASE/Tests/nginx/post_tlszc.py $fname $result.tlszc.csv 
$TBASE/Tests/nginx/post_nvmetls.py $fname $result.nvmetls.csv 
$TBASE/Tests/nginx/post_nvmetls_lat.py $fname $result.nvmetls_lat.csv 

# threads
grep nginx-0-1 $result.csv | sort -t, -k11 -n > $result.1.csv
grep nginx-0-2 $result.csv | sort -t, -k11 -n > $result.2.csv
grep nginx-0-4 $result.csv | sort -t, -k11 -n > $result.4.csv
grep nginx-0-6 $result.csv | sort -t, -k11 -n > $result.6.csv
grep nginx-0-8 $result.csv | sort -t, -k11 -n > $result.8.csv

# threads without 1MB
grep nginx-0-1 $result.csv | sort -t, -k11 -n | head -n 5 > $result.1.s.csv
grep nginx-0-2 $result.csv | sort -t, -k11 -n | head -n 5 > $result.2.s.csv
grep nginx-0-4 $result.csv | sort -t, -k11 -n | head -n 5 > $result.4.s.csv
grep nginx-0-6 $result.csv | sort -t, -k11 -n | head -n 5 > $result.6.s.csv
grep nginx-0-8 $result.csv | sort -t, -k11 -n | head -n 5 > $result.8.s.csv

# conns
grep "\-2000" $result.csv > $result.c.2000.csv
grep "\-4000" $result.csv > $result.c.4000.csv
grep "\-6000" $result.csv > $result.c.6000.csv
grep "\-8000" $result.csv > $result.c.8000.csv
grep "\-10000" $result.csv > $result.c.10000.csv

# sizes
grep "\-4096"    $result.csv > $result.s.4096.csv
grep "\-16384"   $result.csv > $result.s.16384.csv
grep "\-65536"   $result.csv > $result.s.65536.csv
grep "\-262144"  $result.csv > $result.s.262144.csv
grep "\-1048576" $result.csv > $result.s.1048576.csv

# threads - tls
grep nginx-0-1 $result.tlszc.csv | sort -t, -k12 -n > $result.tlszc.s.1.csv
grep nginx-0-2 $result.tlszc.csv | sort -t, -k12 -n > $result.tlszc.s.2.csv
grep nginx-0-4 $result.tlszc.csv | sort -t, -k12 -n > $result.tlszc.s.4.csv
grep nginx-0-6 $result.tlszc.csv | sort -t, -k12 -n > $result.tlszc.s.6.csv
grep nginx-0-8 $result.tlszc.csv | sort -t, -k12 -n > $result.tlszc.s.8.csv

# sizes - tls
grep "\-4096"    $result.tlszc.csv > $result.tlszc.s.4096.csv
grep "\-16384"   $result.tlszc.csv > $result.tlszc.s.16384.csv
grep "\-65536"   $result.tlszc.csv > $result.tlszc.s.65536.csv
grep "\-262144"  $result.tlszc.csv > $result.tlszc.s.262144.csv
grep "\-1048576" $result.tlszc.csv > $result.tlszc.s.1048576.csv

# threads - nvmetls
grep nginx-0-1 $result.nvmetls.csv | sort -t, -k8 -n > $result.nvmetls.s.1.csv
grep nginx-0-2 $result.nvmetls.csv | sort -t, -k8 -n > $result.nvmetls.s.2.csv
grep nginx-0-4 $result.nvmetls.csv | sort -t, -k8 -n > $result.nvmetls.s.4.csv
grep nginx-0-6 $result.nvmetls.csv | sort -t, -k8 -n > $result.nvmetls.s.6.csv
grep nginx-0-8 $result.nvmetls.csv | sort -t, -k8 -n > $result.nvmetls.s.8.csv

# threads - nvmetls_lat
grep nginx-0-1 $result.nvmetls_lat.csv | sort -t, -k8 -n > $result.nvmetls_lat.s.1.csv
grep nginx-0-2 $result.nvmetls_lat.csv | sort -t, -k8 -n > $result.nvmetls_lat.s.2.csv
grep nginx-0-4 $result.nvmetls_lat.csv | sort -t, -k8 -n > $result.nvmetls_lat.s.4.csv
grep nginx-0-6 $result.nvmetls_lat.csv | sort -t, -k8 -n > $result.nvmetls_lat.s.6.csv
grep nginx-0-8 $result.nvmetls_lat.csv | sort -t, -k8 -n > $result.nvmetls_lat.s.8.csv

# medians
head -n 1 $result.csv > $result.median.csv
sort -t, -k10 -n  $result.1.csv | head -n $[ $[`cat $result.1.csv | wc -l` + 1]/ 2] | tail -n 1 >> $result.median.csv
sort -t, -k10 -n  $result.2.csv | head -n $[ $[`cat $result.2.csv | wc -l` + 1]/ 2] | tail -n 1 >> $result.median.csv
sort -t, -k10 -n  $result.4.csv | head -n $[ $[`cat $result.4.csv | wc -l` + 1]/ 2] | tail -n 1 >> $result.median.csv

#gnuplot nginx.plot
#gnuplot nginx2.plot

#gnuplot nginx.size.1.plot
#gnuplot nginx.size.2.plot
#gnuplot nginx.size.4.plot
#gnuplot nginx.size.6.plot
#gnuplot nginx.size.8.plot
#gnuplot nginx.size.all.plot
#gnuplot nginx.size.all.cpu.plot
#gnuplot nginx.size.all.cpu2.plot
#gnuplot nginx.size.all.cpu3.plot
#gnuplot nginx.size.all.cpu4.plot

#gnuplot nginx.size.all.cpu5.plot
#gnuplot nginx.tlszc.size.all.cpu5.plot
#gnuplot nginx.nvmetls.size.all.cpu5.plot
#gnuplot nginx.gp
#gnuplot nginx.tls.gp
#gnuplot nginx.nvmetls.gp

gnuplot nginx3.gp
gnuplot nginx3_tls.gp
gnuplot nginx3b_tls.gp
gnuplot nginx3_tls_small.gp
gnuplot nginx3_nvmetls.gp
