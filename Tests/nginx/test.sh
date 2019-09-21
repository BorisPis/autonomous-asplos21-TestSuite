#!/bin/bash

SUITE=$TBASE/TestSuite/
TEST=$SUITE/Tests/nginx

WRK=$TBASE/wrk
#NGINX=$TBASE/nginx/objs/nginx
NGINX=$SUITE/Apps/ssl/nginx/objs/nginx

################################
[ ! -f /sys/module/tls/parameters/zerocopy ] && echo "missing zerocopy parameter" && exit
[ -z "$CORES" ] && CORES=4
[ -z "$ZC" ] && ZC=0
[ -z "$ZCOPY" ] && ZCOPY=0
[ -z "$ZCRC" ] && ZCRC=0
[ -z "$THREADS" ] && THREADS=16
[ -z "$CONNS" ] && CONNS=128
[ -z "$TIME" ] && TIME=60
[ -z "$MODE" ] && MODE=http
[ -z "$REMOTE_IP" ] && REMOTE_IP=$ip1
[ -z "$OUTPUT" ] && OUTPUT=/tmp/
[ -z "$FSIZE" ] && FSIZE=65536
#[ -z "$URL" ] && URL=$WRK/$MODE.$FSIZE.lua
# generic wrk script takes environment variables
[ -z "$URL" ] && URL=$WRK/http.size.lua
[ -z "$NOCGROUP" ] && NOCGROUP=0
[ -z "$NOCGROUP_PATHS" ] && NOCGROUP_PATHS=$[134217728/$FSIZE - 1]
[ -z "$OFFLOAD" ] && OFFLOAD=0
################################

if [ `hostname` == "gen-l-vrt-010.mtl.labs.mlnx" ]; then
    if1l=( 0 1 2 6 7 8 )
    if1l_nginx=( 1 10 100 1000000 10000000 100000000 )
elif [ `hostname` == "dante732" ]; then
    if1l=(`seq 0 2 26`)
    if1l_nginx=( 1 100 10000 1000000 100000000 10000000000 1000000000000 100000000000000 )
else
    echo unknown hostname: `hostname`
    echo modify $0 to add local cores
    exit
fi

case $OFFLOAD in
	0)
		echo no offload;
		sudo ethtool -K $if1 tls-hw-tx-offload off
		KTLS="-K"
		;;
	1)
		echo offload enabled;
		KTLS="-K"
		sudo ethtool -K $if1 tls-hw-tx-offload on
		echo 0 | sudo tee /sys/module/tls/parameters/zerocopy
		;;
	2)
		echo offload enabled;
		KTLS="-K"
		sudo ethtool -K $if1 tls-hw-tx-offload on
		echo 1 | sudo tee /sys/module/tls/parameters/zerocopy
		;;
	3)
		echo "offload --> http";
		KTLS=""
		sudo ethtool -K $if1 tls-hw-tx-offload off
		echo 0 | sudo tee /sys/module/tls/parameters/zerocopy
		MODE=http
		;;
esac

if [ $CONNS -ge "10000" ]; then
	sudo tc qdisc add dev $if1 root handle 1:0 fq maxrate $[100000/$CONNS]Mbit
else
	sudo tc qdisc del dev $if1 root
fi


#if [ $OFFLOAD == 0 ]; then
#    echo no offload;
#    sudo ethtool -K $if1 tls-hw-tx-offload off
#    KTLS=""
#else
#    echo offload enabled;
#    KTLS="-K"
#    sudo ethtool -K $if1 tls-hw-tx-offload on
#    if [ $OFFLOAD == 2 ]; then
#        echo 1 | sudo tee /sys/module/tls/parameters/zerocopy
#    else
#        echo 0 | sudo tee /sys/module/tls/parameters/zerocopy
#    fi
#fi

#################################
if [ $CORES -eq "8" ]; then
	#CORE_LIST="0,2,4,6,8,10,12,14"
	#sudo set_irq_affinity_cpulist.sh 0,2,4,6,8,10,12,14 $if1
	#AFF=" 1 100 10000 1000000 100000000 10000000000 1000000000000 100000000000000 "
	printf -v CORE_LIST "%s," "${if1l[@]:0:8}"
	CORE_LIST=${CORE_LIST%?}
	sudo set_irq_affinity_cpulist.sh $CORE_LIST $if1
	AFF=${if1l_nginx[@]:0:8}
elif [ $CORES -eq "6" ]; then
	#CORE_LIST="0,2,4,6,8,10"
	#sudo set_irq_affinity_cpulist.sh 0,2,4,6,8,10 $if1
	#AFF=" 1 100 10000 1000000 100000000 10000000000 "
	printf -v CORE_LIST "%s," "${if1l[@]:0:6}"
	CORE_LIST=${CORE_LIST%?}
	sudo set_irq_affinity_cpulist.sh $CORE_LIST $if1
	AFF=${if1l_nginx[@]:0:6}
elif [ $CORES -eq "4" ]; then
	#CORE_LIST="0,2,4,6"
	#sudo set_irq_affinity_cpulist.sh 0,2,4,6 $if1
	#AFF=" 1 100 10000 1000000"
	printf -v CORE_LIST "%s," "${if1l[@]:0:4}"
	CORE_LIST=${CORE_LIST%?}
	sudo set_irq_affinity_cpulist.sh $CORE_LIST $if1
	AFF=${if1l_nginx[@]:0:4}
elif [ $CORES -eq "2" ]; then
	#CORE_LIST="0,2"
	#sudo set_irq_affinity_cpulist.sh 0,2 $if1
	#AFF=" 1 100"
	printf -v CORE_LIST "%s," "${if1l[@]:0:2}"
	CORE_LIST=${CORE_LIST%?}
	sudo set_irq_affinity_cpulist.sh $CORE_LIST $if1
	AFF=${if1l_nginx[@]:0:2}
elif [ $CORES -eq "1" ]; then
	#CORE_LIST="0"
	#sudo set_irq_affinity_cpulist.sh 0 $if1
	#AFF=" 1"
	printf -v CORE_LIST "%s," "${if1l[@]:0:1}"
	CORE_LIST=${CORE_LIST%?}
	sudo set_irq_affinity_cpulist.sh $CORE_LIST $if1
	AFF=${if1l_nginx[@]:0:1}
else
	echo Unsupported cores $CORES
	exit
fi
#################################

sudo -E $NGINX -s stop
sleep 1
#[ `ps -fade | grep nginx | wc -l` -gt 2 ] && echo nginx still running!! && exit -1
#sudo pkill nginx
ssh $loader1 pkill wrk

sudo cp $TEST/nginx.conf /usr/local/nginx/conf/

sudo -E cgdelete -g memory:/nginx
if [ $NOCGROUP == 0 ]; then
    sudo -E cgcreate -g memory:/nginx
    sudo cgset -r memory.limit_in_bytes=512m nginx
    sudo cgset -r memory.swappiness=0 nginx
    CGCMD="cgexec -g memory:/nginx --sticky "
    echo $SUITE/Scripts/drop_vm_cache.sh
    $SUITE/Scripts/drop_vm_cache.sh
    MAXPATHS=$[8589934592/$FSIZE - 1]
    echo "[+] fetching all inodes for $TBASE/nvme/mount/nginx.$FSIZE"
    t1=`date +%s`
    time ls -l $TBASE/nvme/mount/nginx.$FSIZE > /dev/null # fetch all inodes
    t2=`date +%s`
    RAMP=$[$t2-$t1] # Experimentally this takes about 45 sec for 4096

else
    CGCMD=""
    MAXPATHS=$NOCGROUP_PATHS
    #URL=$MODE.$FSIZE.short.lua
    RAMP=0
fi

nvme=`ls -l --color=never /dev/nvme*n1 | awk '{print  $10}'`
nvme_base=`basename $nvme`
echo $[$FSIZE/1024]           | sudo tee /sys/block/$nvme_base/queue/read_ahead_kb

echo "sudo -E $CGCMD $NGINX $KTLS -c $TEST/nginx.conf -g \"worker_processes $CORES; worker_cpu_affinity $AFF;\""
sudo -E $CGCMD $NGINX $KTLS -c $TEST/nginx.conf -g "worker_processes $CORES; worker_cpu_affinity $AFF;"

# set zerocopy
echo $ZC    | sudo tee /sys/module/nvme_tcp/parameters/nvmeotcp_req
echo $ZCOPY | sudo tee /sys/module/nvme_tcp/parameters/nvmeotcp_zerocopy
echo $ZCRC  | sudo tee /sys/module/nvme_tcp/parameters/nvmeotcp_zerocrc

echo ssh $loader1 "cd $WRK; maxpaths=$MAXPATHS mode=$MODE fsize=$FSIZE dip1=$ip1 $TBASE/wrk/wrk --timeout 100 -t $THREADS -c $CONNS -d $[$TIME-$RAMP] -s $URL $MODE://$REMOTE_IP"
ssh $loader1 "cd $WRK; maxpaths=$MAXPATHS mode=$MODE fsize=$FSIZE dip1=$ip1 $TBASE/wrk/wrk -L --timeout 100 -t $THREADS -c $CONNS -d $[$TIME-$RAMP] -s $URL $MODE://$REMOTE_IP" | tee -a $OUTPUT/nginx.txt &
