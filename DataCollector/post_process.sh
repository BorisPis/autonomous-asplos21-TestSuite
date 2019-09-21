#!/bin/bash

export HOME=/homes/markuze
perf=/homes/markuze/copy/tools/perf/perf

function report_functions {
	echo " in report_functions"
	#sudo /homes/markuze/copy/tools/perf/perf report --stdio --max-stack 0 --percent-limit 0.01  >> $OUT_FILE/perf.txt
	perf_name=`date +"%y_%m_%d_%H.%M.%S"`
	#sudo cp perf.data $OUT_FILE/$perf_name.data
	#sudo /homes/markuze/copy/tools/perf/perf mem report --stdio >> $OUT_FILE/perf.txt
	sudo $perf report -i mem.data -C 1 -n --mem-mode --stdio 			> ../$OUT_FILE/perf_${perf_name}_mem_1.txt
	sudo $perf report -i mem.data -C 3 -n --mem-mode --stdio 			> ../$OUT_FILE/perf_${perf_name}_mem_3.txt
	sudo $perf report -C 1 -i cpu.data --show-cpu-utilization --stdio		> ../$OUT_FILE/perf_${perf_name}_cpu_1.txt
	sudo $perf report -C 1 -i cpu.data --show-cpu-utilization --stdio --no-child	> ../$OUT_FILE/perf_${perf_name}_cpu_1_nc.txt
	sudo $perf report -C 3 -i cpu.data --show-cpu-utilization --stdio		> ../$OUT_FILE/perf_${perf_name}_cpu_3.txt
	sudo $perf report -C 3 -i cpu.data --show-cpu-utilization --stdio --no-child	> ../$OUT_FILE/perf_${perf_name}_cpu_3_nc.txt

	echo " out report_functions"
}

cd `dirname $0`
[ "$collect_functions" != "no" ] && report_functions
