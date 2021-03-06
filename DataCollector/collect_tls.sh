#!/bin/bash

perf=/homes/borispi/linux/tools/perf/perf
pcm=/homes/borispi/pcm/
time=5
base=`dirname $0`

echo "<$OUT_FILE>"
function collect_net_cpu {
	#$base/collect_net_cpu.pl &
    echo " in collect cpu" >&2
    $base/pylib/sample_cpu.py $[$time*4]      | tee -a $OUT_FILE/cpu.txt &
    echo if1 $if1
    $base/pylib/sample_eth.py $[$time*4] $if1 | tee -a $OUT_FILE/eth.txt &
    echo " out collect cpu" >&2
}

function collect_mem_bw {
	echo " in collect mem bw" >&2
	sudo $pcm/pcm-memory.x 1 -- sleep $[$time*2] | tee -a $OUT_FILE/memory.txt
	echo " out collect mem bw" >&2
}

function collect_nvme_trace {
	echo 1 | sudo tee /sys/module/nvme_tcp/parameters/trace
	sleep $[$time*4]
	echo 0 | sudo tee /sys/module/nvme_tcp/parameters/trace
	sudo dmesg | tail -n 61
}

function collect_tls_trace {
	echo 1 | sudo tee /sys/module/tls/parameters/trace
	sleep $[$time*4]
	echo 0 | sudo tee /sys/module/tls/parameters/trace
	sleep 1
	sudo dmesg | tail -n 3 | tee -a $OUT_FILE/dmesg_tls_trace.txt
}

#function collect_tls_remote_trace {
#	ssh -t $dip1 "echo 1 | sudo tee /sys/module/tls/parameters/trace"
#	sleep $[$time*4]
#	ssh -t $dip1 "echo 0 | sudo tee /sys/module/tls/parameters/trace"
#	ssh -t $dip1 "sudo dmesg | tail -n 3"
#}

#function collect_tls_decrypt {
#    echo " in collect tls_decrypt" >&2
#    $base/pylib/sample_tls_decrypt.py $[$time*4]      | tee -a $OUT_FILE/tls_decrypt.txt &
#    echo " out collect tls_decrypt" >&2
#}

function collect_pcm {
	echo " in collect pcm" >&2
	sudo $pcm/pcm-pcie.x 1 -- sleep $time | tee -a $OUT_FILE/pcie.txt
	#sudo $pcm/pcm-pcie.x 1 -csv=/tmp/pcie_csv.txt -- sleep $time #| tee -a $OUT_FILE/pcie.txt
	#mv /tmp/pcie_csv.txt $OUT_FILE
	#sudo $pcm/pcm-latency.x -- sleep $time| tee -a $OUT_FILE/latency.txt 
	#sudo $pcm/pcm-power.x -- sleep $time| tee -a $OUT_FILE/power.txt 
	sudo $pcm/pcm.x 1 -- sleep $time| tee -a $OUT_FILE/pcm.txt 
	echo " out collect pcm" >&2
}

[ "$collect_net_cpu" != "no" ] && collect_net_cpu
#[ "$collect_mem_bw" != "no" ] && collect_mem_bw
#[ "$collect_nvme_trace" != "no" ] && collect_nvme_trace
[ "$collect_tls_trace" != "no" ] && collect_tls_trace
#[ "$collect_tls_decrypt" != "no" ] && collect_tls_decrypt
#[ "$collect_tls_remote_trace" != "no" ] && collect_tls_remote_trace
#[ "$collect_pcm" != "no" ] && collect_pcm

echo "Data collected"
