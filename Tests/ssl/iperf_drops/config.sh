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
[ -z "$ISENC" ] && ISENC=0

#####################
#sudo set_irq_affinity_bynode.sh $LCN $if1
ssh -t $loader1 sudo set_irq_affinity_bynode.sh $RCN $dif1
#ssh -t $loader1 sudo set_irq_affinity.sh $dif1
sudo set_irq_affinity_cpulist.sh 0 $if1
#ssh -t $loader1 sudo set_irq_affinity_cpulist.sh 0 $dif1

#####################
SOCK_SIZE=$((256 * 1024 * 1024));
sudo sh -c "echo $SOCK_SIZE > /proc/sys/net/core/optmem_max"
sudo sh -c "echo $SOCK_SIZE > /proc/sys/net/core/rmem_max"
sudo sh -c "echo $SOCK_SIZE > /proc/sys/net/core/wmem_max"
sudo sh -c "echo $SOCK_SIZE > /proc/sys/net/core/rmem_default"
sudo sh -c "echo $SOCK_SIZE > /proc/sys/net/core/wmem_default"
sudo sh -c "echo 1 > /proc/sys/net/ipv4/tcp_syncookies"

ssh -t $loader1 "echo $SOCK_SIZE | sudo tee /proc/sys/net/core/optmem_max"
ssh -t $loader1 "echo $SOCK_SIZE | sudo tee /proc/sys/net/core/rmem_max"
ssh -t $loader1 "echo $SOCK_SIZE | sudo tee /proc/sys/net/core/wmem_max"
ssh -t $loader1 "echo $SOCK_SIZE | sudo tee /proc/sys/net/core/rmem_default"
ssh -t $loader1 "echo $SOCK_SIZE | sudo tee /proc/sys/net/core/wmem_default"
ssh -t $loader1 "echo 1 | sudo tee /proc/sys/net/ipv4/tcp_syncookies"
#####################
# server
#ssh gen-l-vrt-10 'echo 0 > /sys/module/mlx5_core/parameters/tls_crypto_skip'
echo 102400 | sudo tee /proc/sys/net/core/somaxconn
#echo 8 | sudo tee /proc/sys/net/ipv4/tcp_min_tso_segs
echo 102400 | sudo tee /proc/sys/net/ipv4/tcp_max_syn_backlog
echo 1 | sudo tee /proc/sys/net/ipv4/tcp_syncookies 

# client
ssh -t $loader1 sudo sysctl net.ipv4.tcp_fin_timeout=1
ssh -t $loader1 sudo sysctl net.ipv4.tcp_tw_recycle=1
ssh -t $loader1 sudo sysctl net.ipv4.tcp_tw_reuse=1
ssh -t $loader1 sudo sysctl net.ipv4.ip_local_port_range="15000 61000"
sudo sysctl net.ipv4.tcp_fin_timeout=1
sudo sysctl net.ipv4.tcp_tw_recycle=1
sudo sysctl net.ipv4.tcp_tw_reuse=1
sudo sysctl net.ipv4.ip_local_port_range="15000 61000"

#####################
# congestion control - Cubic - BBR
sudo sysctl net.ipv4.tcp_congestion_control=cubic
ssh -t $loader1 sudo sysctl net.ipv4.tcp_congestion_control=cubic
ssh -t $loader1 sudo modprobe -v sch_netem
#sudo modprobe -v tcp_bbr
#ssh -t $loader1 sudo modprobe -v tcp_bbr
#if [ $ISENC == 1 ]; then
#    sudo sysctl net.ipv4.tcp_congestion_control=bbr
#    ssh -t $loader1 sudo sysctl net.ipv4.tcp_congestion_control=bbr
#else
#    sudo sysctl net.ipv4.tcp_congestion_control=cubic
#    ssh -t $loader1 sudo sysctl net.ipv4.tcp_congestion_control=cubic
#fi

#####################

ssh -t $loader1 "echo 0 | sudo tee /sys/module/mlx5_core/parameters/mlx5_drop_prob"
echo 0 | sudo tee /sys/module/mlx5_core/parameters/mlx5_drop_prob

#####################
LRO=off
NOCACHE=on
#TLS_TX=on
#TLS_RX=off
sudo ethtool -K $if1 lro $LRO
ssh -t $loader1 sudo ethtool -K $dif1 lro $LRO
sudo ethtool -K $if1 tx-nocache-copy $NOCACHE
ssh -t $loader1 sudo ethtool -K $dif1 tx-nocache-copy $NOCACHE
