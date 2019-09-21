#!/bin/bash

if [ -z "$TBASE" ]; then
	echo "TestSuite base not configured TBASE=$TBASE"
	exit -1
fi

if [ -z "$nvme1" ]; then
	echo "nvme not configured $nvme1"
	exit -1
fi

if [ -z "$if1" ]; then
	echo "if1 not configured $if1"
	exit -1
fi

if [ -z "$ip1" ]; then
	echo "ip1 not configured $ip1"
	exit -1
fi

if [ -z "$dip1" ]; then
	echo "dip1 not configured $dip1"
	exit -1
fi

[ -z "$LCN" ] && LCN=$if1ln
[ -z "$RCN" ] && RCN=$dif1ln

#####################
#sudo set_irq_affinity_bynode.sh $LCN $if1
#ssh -t $dip1 sudo set_irq_affinity_bynode.sh $RCN $dif1
sudo set_irq_affinity_cpulist.sh 0 $if1
ssh -t $dip1 sudo set_irq_affinity_cpulist.sh 0 $dif1

#####################
SOCK_SIZE=$((256 * 1024 * 1024));
sudo sh -c "echo $SOCK_SIZE > /proc/sys/net/core/optmem_max"
sudo sh -c "echo $SOCK_SIZE > /proc/sys/net/core/rmem_max"
sudo sh -c "echo $SOCK_SIZE > /proc/sys/net/core/wmem_max"
sudo sh -c "echo $SOCK_SIZE > /proc/sys/net/core/rmem_default"
sudo sh -c "echo $SOCK_SIZE > /proc/sys/net/core/wmem_default"

ssh -t $dip1 "echo $SOCK_SIZE | sudo tee /proc/sys/net/core/optmem_max"
ssh -t $dip1 "echo $SOCK_SIZE | sudo tee /proc/sys/net/core/rmem_max"
ssh -t $dip1 "echo $SOCK_SIZE | sudo tee /proc/sys/net/core/wmem_max"
ssh -t $dip1 "echo $SOCK_SIZE | sudo tee /proc/sys/net/core/rmem_default"
ssh -t $dip1 "echo $SOCK_SIZE | sudo tee /proc/sys/net/core/wmem_default"

#####################
LRO=off
sudo ethtool -K $if1 lro $LRO
ssh -t $dip1 sudo ethtool -K $dif1 lro $LRO
#sudo ethtool -C $if1 adaptive-rx $INTER_COAL
#ssh -t $dip1 sudo ethtool -C $dif1 adaptive-rx $INTER_COAL

#####################

sudo ethtool -K $if1 tls-hw-rx-offload off
ssh -t $loader1 sudo ethtool -K $dif1 tls-hw-rx-offload on
ssh -t $loader1 sudo ethtool -K $dif1 tls-hw-tx-offload off

#####################
sudo modprobe -v nvme_tcp
# disable zerocopy/crc/etc.
echo 0 | sudo tee /sys/module/nvme_tcp/parameters/nvmeotcp_*
sudo nvme disconnect-all /dev/nvme0

if [ -z "$NVMETLS" ] || [ "$NVMETLS" == "0" ]; then
    echo "[+] Not using NVMETLS"
    PORT=4420
    echo 0 | sudo tee /sys/module/nvme_tcp/parameters/nvmeotcp_tls_rx
    ssh -t $loader1 "echo 0 | sudo tee /sys/module/nvmet_tcp/parameters/nvmeotcp_tls_tx"
else
    echo "[+] using NVMETLS"
    PORT=4420
    echo 1 | sudo tee /sys/module/nvme_tcp/parameters/nvmeotcp_tls_rx
    ssh -t $loader1 "echo 1 | sudo tee /sys/module/nvmet_tcp/parameters/nvmeotcp_tls_tx"
    ssh -t $loader1 sudo ethtool -K $dif1 tls-hw-tx-offload on
	if [ -z "$NVMETLS_OFFLOAD" ] || [ "$NVMETLS_OFFLOAD" == "0" ]; then
		echo "[-] No NVME-TLS offload"
		sudo ethtool -K $if1 tls-hw-rx-offload off
	else
		echo "[+] NVME-TLS offload"
		sudo ethtool -K $if1 tls-hw-rx-offload on
	fi
fi

#####################

CRC=1 QUEUES=1 $TBASE/Scripts/nvmeh_reload.sh
for i in `seq 1 5`; do
	[ -z "`ls -l /dev/nvme*n1`" ] && sleep 1
done
[ -z "`ls -l /dev/nvme*n1`" ] && echo 'no nvme' && exit
#export nvme1=`ls -l /dev/nvme*n1 | awk '{print  $10}'`
export nvme1=`ls -l /dev/nvme*n1 | awk '{print  $10}' | awk -F/ '{print $3}'`
echo "using drive: $nvme1"

#####################
# disable merging
echo 2 | sudo tee /sys/block/$nvme1/queue/nomerges
# no io scheduler
echo none | sudo tee /sys/block/$nvme1/queue/scheduler
# more requests
echo "1024" | sudo tee /sys/block/$nvme1/queue/nr_requests
