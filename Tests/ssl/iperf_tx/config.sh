#!/bin/bash

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
TLS=off
sudo ethtool -K $if1 lro $LRO
ssh -t $dip1 sudo ethtool -K $dif1 lro $LRO
#sudo ethtool -C $if1 adaptive-rx $INTER_COAL
#ssh -t $dip1 sudo ethtool -C $dif1 adaptive-rx $INTER_COAL
sudo ethtool -K $if1 tls-hw-tx-offload off
sudo ethtool -K $if1 tls-hw-rx-offload off
ssh -t $dip1 sudo ethtool -K $if1 tls-hw-tx-offload off
ssh -t $dip1 sudo ethtool -K $if1 tls-hw-rx-offload off

sudo modprobe -v tls
