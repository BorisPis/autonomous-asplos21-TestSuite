#!/bin/bash

perf=/homes/markuze/copy/tools/perf/perf
pcm=/homes/markuze/pcm/
time=5

function collect_cpu {
	`dirname $0`/collect_net_cpu.pl &
}

function collect_pstats {
	echo " in collect pstas" >&2
	taskset -c 15 $perf stat -a -B -e cycles,instructions,cache-misses,cache-references sleep $time
	taskset -c 15 $perf stat -a -B -e LLC-store,LLC-store-misses sleep $time
	taskset -c 15 $perf stat -a -B -e LLC-load,LLC-load-misses sleep $time
	echo " out collect pstas" >&2
}

function collect_mem_bw {
	echo " in collect mem bw" >&2
	$pcm/pcm-memory.x -- sleep $time
	echo " out collect mem bw" >&2
}

function collect_functions {
	echo " in collect funcs" >&2
	taskset -c 15 $perf record -g -a sleep $time
	echo " out collect funcs" >&2
}

function collect_pcm {
	echo " in collect pcm" >&2
	$pcm/pcm-pcie.x -- sleep $time
	$pcm/pcm.x -- sleep $time
	echo " out collect pcm" >&2
}

[ "$collect_cpu" != "no" ] && collect_cpu
#[ "$collect_pstats" != "no" ] && collect_pstats
[ "$collect_mem_bw" != "no" ] && collect_mem_bw
#[ "$collect_functions" != "no" ] && collect_functions
[ "$collect_pcm" != "no" ] && collect_pcm

echo "Data collected"
