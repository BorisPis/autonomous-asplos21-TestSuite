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
ssh -t $dip1 sudo set_irq_affinity_bynode.sh $RCN $dif1
#ssh -t $dip1 sudo set_irq_affinity_cpulist.sh 0 $dif1

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

CRC=1 QUEUES=1 $TBASE/Scripts/nvmeh_reload.sh
[ -z "`ls -l /dev/nvme*n1`" ] && echo 'no nvme'
export nvme1=`/bin/ls -l /dev/nvme*n1 | tail -n 1 | cut -d " " -f 10`
echo "using drive: $nvme1"

NODC=1 CRC=1 QUEUES=1 PORT=4421 $TBASE/Scripts/nvmeh_reload.sh
[ -z "`ls -l /dev/nvme*n1`" ] && echo 'no nvme'
export nvme2=`/bin/ls -l /dev/nvme*n1 | tail -n 1 | awk '{print  $10}'`
echo "using drive: $nvme2"

NODC=1 CRC=1 QUEUES=1 PORT=4422 $TBASE/Scripts/nvmeh_reload.sh
[ -z "`ls -l /dev/nvme*n1`" ] && echo 'no nvme'
export nvme3=`/bin/ls -l /dev/nvme*n1 | tail -n 1 | awk '{print  $10}'`
echo "using drive: $nvme3"
#####################
# disable merging
snvme1=`echo $nvme1 | sed  's/\/dev\///g'`
echo 2 | sudo -E tee /sys/block/$snvme1/queue/nomerges
# no io scheduler
echo none | sudo -E tee /sys/block/$snvme1/queue/scheduler
# more requests
echo "1024" | sudo -E tee /sys/block/$snvme1/queue/nr_requests
#####################
# disable merging
snvme2=`echo $nvme2 | sed  's/\/dev\///g'`
echo 2 | sudo -E tee /sys/block/$snvme2/queue/nomerges
# no io scheduler
echo none | sudo -E tee /sys/block/$snvme2/queue/scheduler
# more requests
echo "1024" | sudo -E tee /sys/block/$snvme2/queue/nr_requests
#####################
# disable merging
snvme3=`echo $nvme3 | sed  's/\/dev\///g'`
echo 2 | sudo -E tee /sys/block/$snvme3/queue/nomerges
# no io scheduler
echo none | sudo -E tee /sys/block/$snvme3/queue/scheduler
# more requests
echo "1024" | sudo -E tee /sys/block/$snvme3/queue/nr_requests
