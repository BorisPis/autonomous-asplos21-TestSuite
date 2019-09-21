[ -e "./config.sh" ] && source ./config.sh
`dirname $0`/replace.sh
PFC='on'
LRO='off'
GRO='on'
GSO='on'
[ -z "$RING" ] && RING=1024
[ -z "$TX_RING" ] && TX_RING=1024
[ -z "$TX_CACHE" ] && TX_CACHE='off'


function die
{
	echo "$@"
	exit -1;
}

for i in `seq 1 6`;
do
	name="if$i"
	eval if=\$$name;
	name="ip$i"
	eval ip=\$$name;

	if [ ! -z "$if" ]; then
		[ -z "$ip" ] && die "ERROR: echo ip$i ($ip) not configured for $if"

		sudo ifconfig $if $ip netmask 255.255.255.0 mtu $mtu
		sudo ethtool -G $if rx $RING tx $TX_RING
		sudo ethtool -K $if lro $LRO
		sudo ethtool -K $if gro $GRO
		sudo ethtool -K $if gso $GSO
		sudo ethtool -A $if rx $PFC tx $PFC
		sudo ethtool -K $if tx-nocache-copy $TX_CACHE
		sudo ethtool -g $if
		sudo ethtool -k $if
		sudo ethtool -a $if
		sudo tc qdisc del dev $if
		#sudo tc qdisc add dev $if root fq
	fi
done

function setup_peers {

	ssh $loader1 sudo ifconfig $dif1 $dip1 netmask 255.255.255.0 mtu $mtu
	ssh $loader2 sudo ifconfig $dif2 $dip2 netmask 255.255.255.0 mtu $mtu
	ssh $loader2 sudo ifconfig $dif3 $dip3 netmask 255.255.255.0 mtu $mtu
	ssh $loader1 sudo ifconfig $dif4 $dip4 netmask 255.255.255.0 mtu $mtu
	ssh $loader1 sudo ethtool -K $dif1 lro $LRO
	ssh $loader1 sudo ethtool -K $dif1 gro $GRO
	ssh $loader1 sudo ethtool -K $dif1 gso $GSO
	ssh $loader1 sudo ethtool -A $dif1 rx $PFC tx $PFC
	ssh $loader1 sudo ethtool -K $dif4 lro $LRO
	ssh $loader1 sudo ethtool -K $dif4 gro $GRO
	ssh $loader1 sudo ethtool -K $dif4 gso $GSO
	ssh $loader1 sudo ethtool -A $dif4 rx $PFC tx $PFC
	ssh $loader2 sudo ethtool -K $dif2 lro $LRO
	ssh $loader1 sudo ethtool -K $dif2 gro $GRO
	ssh $loader1 sudo ethtool -K $dif2 gso $GSO
	ssh $loader2 sudo ethtool -A $dif2 rx $pfc tx $pfc
	ssh $loader2 sudo ethtool -K $dif3 lro $LRO
	ssh $loader1 sudo ethtool -K $dif3 gro $GRO
	ssh $loader1 sudo ethtool -K $dif3 gso $GSO
	ssh $loader2 sudo ethtool -A $dif3 rx $pfc tx $pfc

	ssh $loader1 sudo set_irq_affinity.sh $dif1
	ssh $loader1 sudo set_irq_affinity.sh $dif4
	ssh $loader2 sudo set_irq_affinity.sh $dif2
	ssh $loader2 sudo set_irq_affinity.sh $dif3

	ssh $loader1 sudo tc qdisc del dev $dif1
	ssh $loader1 sudo tc qdisc del dev $dif4
	ssh $loader2 sudo tc qdisc del dev $dif2
	ssh $loader2 sudo tc qdisc del dev $dif3

	#ssh $loader1 sudo tc qdisc add dev $dif1 root fq
	#ssh $loader1 sudo tc qdisc add dev $dif4 root fq
	#ssh $loader2 sudo tc qdisc add dev $dif2 root fq
	#ssh $loader2 sudo tc qdisc add dev $dif3 root fq
}

setup_peers

sudo modprobe msr
sudo sh -c "echo 8 > /proc/sys/vm/percpu_pagelist_fraction"
sudo sh -c "echo 0 > /proc/sys/kernel/nmi_watchdog"
sudo sh -c "echo 10 > /proc/sys/kernel/panic"

echo -1 | sudo tee /proc/sys/kernel/perf_event_paranoid
echo 0 | sudo tee /proc/sys/kernel/kptr_restrict

# Disable turbo boost
echo 1 | sudo tee /sys/devices/system/cpu/intel_pstate/no_turbo
# Disable turo boost 2
sudo wrmsr -a 0x1a0 0x4000850089


## TODO: set cpupower to maximum
#sudo ~/work/linux/tools/power/cpupower -c all frequency-set -f 3.2GHz

#sudo sh -c "echo 64 > /sys/kernel/debug/tracing/buffer_size_kb"
#sudo sh -c "echo 1 > /proc/sys/kernel/panic_on_oops"
#ssh $loader1 sudo sh -c "echo 65535 > /proc/sys/net/ipv4/tcp_min_tso_segs"
#ssh $loader2 sudo sh -c "echo 65535 > /proc/sys/net/ipv4/tcp_min_tso_segs"

echo "Ring size: $RING"
echo "TX no cache: $TX_CACHE"

[ -z  "$SOCK_SIZE" ] && exit

echo "Sock size: $SOCK_SIZE"
#SOCK_SIZE=1073741824
#SOCK_SIZE=270217728
sudo sh -c "echo $SOCK_SIZE > /proc/sys/net/core/optmem_max"
sudo sh -c "echo $SOCK_SIZE > /proc/sys/net/core/rmem_max"
sudo sh -c "echo $SOCK_SIZE > /proc/sys/net/core/wmem_max"
sudo sh -c "echo $SOCK_SIZE > /proc/sys/net/core/rmem_default"
sudo sh -c "echo $SOCK_SIZE > /proc/sys/net/core/wmem_default"


cat /proc/sys/net/core/optmem_max
cat /proc/sys/net/core/rmem_max
cat /proc/sys/net/core/wmem_max
cat /proc/sys/net/core/rmem_default
cat /proc/sys/net/core/wmem_default
