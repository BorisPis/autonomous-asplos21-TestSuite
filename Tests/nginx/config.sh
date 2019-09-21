#!/bin/bash
SUITE=$TBASE/TestSuite
NGINX=$SUITE/Apps/ssl/nginx/objs/nginx

if [ -z "$if1" ]; then
	echo "if1 not configured $if1"
	exit -1
fi

#####################

[ -z "$LCN" ] && LCN=$if1ln
[ -z "$RCN" ] && RCN=$dif1ln
#sudo set_irq_affinity_bynode.sh $LCN $if1
#ssh -t $loader1 sudo set_irq_affinity_bynode.sh $LCN $dif1
#sudo set_irq_affinity_cpulist.sh 0,2,4,6 $if1
ssh -t $loader1 sudo set_irq_affinity_bynode.sh $LCN $dif1

#####################

SOCK_SIZE=$((256 * 1024 * 1024));
sudo sh -c "echo $SOCK_SIZE > /proc/sys/net/core/optmem_max"
sudo sh -c "echo $SOCK_SIZE > /proc/sys/net/core/rmem_max"
sudo sh -c "echo $SOCK_SIZE > /proc/sys/net/core/wmem_max"
sudo sh -c "echo $SOCK_SIZE > /proc/sys/net/core/rmem_default"
sudo sh -c "echo $SOCK_SIZE > /proc/sys/net/core/wmem_default"

ssh -t $loader1 "echo $SOCK_SIZE | sudo tee /proc/sys/net/core/optmem_max"
ssh -t $loader1 "echo $SOCK_SIZE | sudo tee /proc/sys/net/core/rmem_max"
ssh -t $loader1 "echo $SOCK_SIZE | sudo tee /proc/sys/net/core/wmem_max"
ssh -t $loader1 "echo $SOCK_SIZE | sudo tee /proc/sys/net/core/rmem_default"
ssh -t $loader1 "echo $SOCK_SIZE | sudo tee /proc/sys/net/core/wmem_default"

#####################

# server
#ssh gen-l-vrt-10 'echo 0 > /sys/module/mlx5_core/parameters/tls_crypto_skip'
echo 102400 | sudo tee /proc/sys/net/core/somaxconn
#echo 8 | sudo tee /proc/sys/net/ipv4/tcp_min_tso_segs
echo 102400 | sudo tee /proc/sys/net/ipv4/tcp_max_syn_backlog
echo 0 | sudo tee /proc/sys/net/ipv4/tcp_syncookies 

# client
ssh -t $loader1 sudo sysctl net.ipv4.tcp_fin_timeout=1
ssh -t $loader1 sudo sysctl net.ipv4.tcp_tw_recycle=1
ssh -t $loader1 sudo sysctl net.ipv4.tcp_tw_reuse=1
ssh -t $loader1 sudo sysctl net.ipv4.ip_local_port_range="15000 61000"

#####################
LRO=off
NOCACHE=on
#TLS_TX=on
#TLS_RX=off
sudo ethtool -K $if1 lro $LRO
ssh -t $loader1 sudo ethtool -K $dif1 lro $LRO
sudo ethtool -K $if1 tls-hw-rx-offload off
ssh -t $loader1 sudo ethtool -K $dif1 tls-hw-rx-offload on
ssh -t $loader1 sudo ethtool -K $dif1 tls-hw-tx-offload off
sudo ethtool -K $if1 tx-nocache-copy $NOCACHE
ssh -t $loader1 sudo ethtool -K $dif1 tx-nocache-copy $NOCACHE

#####################
echo killing nginx
sudo -E $NGINX -s stop
#sudo pkill nginx
ssh -t $loader1 sudo pkill -f wrk
echo killed nginx

####################
echo 'sudo umount $TBASE/nvme/mount'
echo 0 | sudo tee /sys/module/nvme_tcp/parameters/nvmeotcp_*
sudo umount $TBASE/nvme/mount
sudo umount $TBASE/nvme/mount
rm -f $TBASE/nvme/mount
#####################

# Cubic
sudo sysctl net.ipv4.tcp_congestion_control=cubic
ssh -t $loader1 sudo sysctl net.ipv4.tcp_congestion_control=cubic

#####################
if [ `hostname` == "gen-l-vrt-010.mtl.labs.mlnx" ] && ! [ -z "$NOCGROUP" ]; then
    sudo umount $TBASE/nvme
    rmdir $TBASE/nvme/mount
    rmdir $TBASE/nvme
    echo "[+] NOCGROUP is defined using small local files"
    ln -s /usr/local/nginx/nvme $TBASE/nvme
    exit
else 
    rm -f $TBASE/nvme/mount
    rm -f $TBASE/nvme
    mkdir -p $TBASE/nvme/mount
fi
#####################
sudo modprobe -v nvme_tcp
# disable zerocopy/crc/etc.
echo 0 | sudo tee /sys/module/nvme_tcp/parameters/nvmeotcp_*
echo 0 | sudo tee /sys/module/tls/parameters/*
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
echo 0 | sudo tee /proc/sys/vm/swappiness
# nvme with queue per core and crc enabled
PORT=$PORT QUEUES=$[3 * `grep -c ^processor /proc/cpuinfo`] CRC=1 $SUITE/Scripts/nvmeh_reload.sh
for i in `seq 1 5`; do
	[ -z "`ls -l /dev/nvme*n1`" ] && sleep 1
done
[ -z "`ls -l /dev/nvme*n1`" ] && echo 'no nvme' && exit
nvme=`ls -l --color=never /dev/nvme*n1 | awk '{print  $10}'`
echo "using drive: $nvme"
export nvme=$nvme

sudo e2fsck -n -f $nvme

echo 'sudo mount -t ext4 -o sync,errors=remount-ro $nvme $TBASE/nvme/mount'
sudo mount -t ext4 -o data=writeback,sync,errors=remount-ro $nvme $TBASE/nvme/mount

#sudo ls $TBASE/nvme/mount/nginx.4096 > /dev/null # fetch all inodes
#sudo ls $TBASE/nvme/mount/nginx/file.11* | wc -l
#for i in `seq 0 1000`; do sudo ls $TBASE/nvme/mount/nginx/file.$i.html > /dev/null; done

#####################
# Disk optimizations
# https://cromwell-intl.com/open-source/performance-tuning/disks.html
#####################
nvme_base=`basename $nvme`
echo mq-deadline | sudo tee /sys/block/$nvme_base/queue/scheduler
echo 2           | sudo tee /sys/block/$nvme_base/queue/iosched/writes_starved
echo 100         | sudo tee /sys/block/$nvme_base/queue/iosched/read_expire
#echo 4           | sudo tee /sys/block/$nvme_base/queue/read_ahead_kb
echo 2           | sudo tee /sys/block/$nvme_base/queue/nomerges
echo 1           | sudo tee /sys/fs/ext4/$nvme_base/inode_readahead_blks
echo 10          | sudo tee /proc/sys/vm/vfs_cache_pressure
echo 0           | sudo tee /proc/sys/vm/overcommit_memory


if [ -z "$LATENCY" ]; then
# throughput oriented
echo "[+] Throughput oriented"

else 
# latency oriented 
echo "[+] Latency oriented"

fi
