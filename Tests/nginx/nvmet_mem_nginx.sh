#!/bin/bash

echo if1=$if1
[ -z "$if1" ] && exit
#[ -z "$memfile" ] && memfile=/dev/shm/memfile
[ -z "$memfile" ] && memfile=$TBASE/nvme/tmpfs
echo memfile=$memfile

# establish nvme target
sudo modprobe -v nvme_loop
sudo modprobe -v nvmet_tcp

#########################
# disconnect previous loop
sudo nvme disconnect-all /dev/nvme1n1
for j in `seq 0 8`;
do
	sudo losetup -d /dev/loop$j
	sudo umount $memfile$[$j*2]
	echo 0 | sudo tee /sys/kernel/config/nvmet/subsystems/ssb1_$[$j*2+1]/namespaces/$[$j*2+1]/enable
	echo 0 | sudo tee /sys/kernel/config/nvmet/subsystems/ssb1_$[$j*2]/namespaces/$[$j*2]/enable
	sudo rm -f /sys/kernel/config/nvmet/ports/$[j*2]/subsystems/ssb1_$[$j*2]
	sudo rm -f /sys/kernel/config/nvmet/ports/$[j*2+1]/subsystems/ssb1_$[$j*2+1]
done

base=0
if [ `ls -l /dev/nvme[0-9]n1 | tail -n 1 | awk '{print $10}'` ]; then
    base=1
fi

#exit

for i in `seq 1 1`;
do
	loop=`losetup -f`
	sudo losetup -P $loop $memfile$[$i*2]
	mkdir $memfile$[$i*2]
	#mount
	sudo mount -t tmpfs -o size=10g none $memfile$[$i*2]
	#consume 10G
	dd if=/dev/zero of=$memfile$[$i*2]/img.bin bs=1M seek=9999 count=1

	# setup loopback
	sudo losetup -P $loop $memfile$[$i*2]/img.bin

    # ext4
    sudo mkfs -t ext4 $loop
    sudo e2fsck -n -f $loop
    sudo umount $TBASE/nvme/mount
    sudo mount -t ext4 -o data=writeback,sync,errors=remount-ro $loop $TBASE/nvme/mount
    FSIZE=262144 ./generate_files.sh
    #mkfs -t ext4 -o data=writeback,sync,errors=remount-ro $memfile$[$i*2] $TBASE/nvme/moun

	echo 0 | sudo tee /sys/kernel/config/nvmet/subsystems/ssb2_$[$i*2]/namespaces/$[$i*2]/enable
	echo enable? 
	cat /sys/kernel/config/nvmet/subsystems/ssb2_$[$i*2]/namespaces/$[$i*2]/enable
	sudo mkdir /sys/kernel/config/nvmet/subsystems/ssb2_$[$i*2]
	echo 1 | sudo tee /sys/kernel/config/nvmet/subsystems/ssb2_$[$i*2]/attr_allow_any_host

	# create namespace and attach the nvme device to it (assume /dev/nullb0 exists)
	sudo mkdir /sys/kernel/config/nvmet/subsystems/ssb2_$[$i*2]/namespaces/$[$i*2]
	echo -n $loop | sudo tee /sys/kernel/config/nvmet/subsystems/ssb2_$[$i*2]/namespaces/$[$i*2]/device_path

	# create nvme target port on $[$i*2]f1
	sudo mkdir /sys/kernel/config/nvmet/ports/$[$i*2]
	echo loop | sudo tee /sys/kernel/config/nvmet/ports/$[$i*2]/addr_trtype
	sudo ln -s /sys/kernel/config/nvmet/subsystems/ssb2_$[$i*2] /sys/kernel/config/nvmet/ports/$[$i*2]/subsystems/ssb2_$[$i*2]
	echo 1 | sudo tee /sys/kernel/config/nvmet/subsystems/ssb2_$[$i*2]/namespaces/$[$i*2]/enable
	# connect to loopback target
	sudo nvme connect-all -t loop -q myloop

	#########################

	# create nvme subsystem ssb1_$[$i*2+1]
	echo 0 | sudo tee /sys/kernel/config/nvmet/subsystems/ssb1_$[$i*2+1]/namespaces/$[$i*2+1]/enable
	sudo mkdir /sys/kernel/config/nvmet/subsystems/ssb1_$[$i*2+1]
	echo 1 | sudo tee /sys/kernel/config/nvmet/subsystems/ssb1_$[$i*2+1]/attr_allow_any_host

	# create namespace and attach the nvme device to it (assume /dev/nullb0 exists)
	ndisk=`ls -l /dev/nvme[$base-9]n1 | tail -n 1 | awk '{print $10}'`
	sudo mkdir /sys/kernel/config/nvmet/subsystems/ssb1_$[$i*2+1]/namespaces/$[$i*2+1]
	echo -n $ndisk | sudo tee /sys/kernel/config/nvmet/subsystems/ssb1_$[$i*2+1]/namespaces/$[$i*2+1]/device_path

	# create nvme target port on $[$i*2+1]f1
	sudo mkdir /sys/kernel/config/nvmet/ports/$[$i*2+1]
	echo `ip addr show $if1 | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}" | head -n 1` | sudo tee /sys/kernel/config/nvmet/ports/$[$i*2+1]/addr_traddr
	echo tcp | sudo tee /sys/kernel/config/nvmet/ports/$[$i*2+1]/addr_trtype
	#echo 4420 | sudo tee /sys/kernel/config/nvmet/ports/$[$i*2+1]/addr_trsvcid
	echo $[4420-1+$base+$i] | sudo tee /sys/kernel/config/nvmet/ports/$[$i*2+1]/addr_trsvcid
	echo ipv4 | sudo tee /sys/kernel/config/nvmet/ports/$[$i*2+1]/addr_adrfam
	echo 1 | sudo tee /sys/kernel/config/nvmet/subsystems/ssb1_$[$i*2+1]/namespaces/$[$i*2+1]/enable

	sudo ln -s /sys/kernel/config/nvmet/subsystems/ssb1_$[$i*2+1] /sys/kernel/config/nvmet/ports/$[$i*2+1]/subsystems/ssb1_$[$i*2+1]

	echo -n "Checking if port is listening..."
	dmesg | grep "enabling port" && echo "Found" || echo "Not Found"
done

