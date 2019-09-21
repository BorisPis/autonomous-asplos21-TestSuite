#!/bin/bash

echo if1=$if1
echo bigfile=$bigfile
[ -z "$if1" ] && exit
[ -z "$bigfile" ] && exit
#if1=mlx0

echo 0 | sudo tee /sys/kernel/config/nvmet/subsystems/ssb2/namespaces/11/enable

sudo modprobe -vr nvmet_tcp
sudo modprobe -v nvmet_tcp

# create nvme subsystem ssb2
sudo mkdir /sys/kernel/config/nvmet/subsystems/ssb2
echo 1 | sudo tee /sys/kernel/config/nvmet/subsystems/ssb2/attr_allow_any_host

# create namespace and attach the nvme device to it (assume /dev/nullb0 exists)
sudo mkdir /sys/kernel/config/nvmet/subsystems/ssb2/namespaces/11
echo -n $bigfile | sudo tee /sys/kernel/config/nvmet/subsystems/ssb2/namespaces/11/device_path
echo 1 | sudo tee /sys/kernel/config/nvmet/subsystems/ssb2/namespaces/11/enable

# create nvme target port on $if1
sudo mkdir /sys/kernel/config/nvmet/ports/1
echo `ip addr show $if1 | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}"` | sudo tee /sys/kernel/config/nvmet/ports/1/addr_traddr
echo tcp | sudo tee /sys/kernel/config/nvmet/ports/1/addr_trtype
echo 4420 | sudo tee /sys/kernel/config/nvmet/ports/1/addr_trsvcid
echo ipv4 | sudo tee /sys/kernel/config/nvmet/ports/1/addr_adrfam

sudo ln -s /sys/kernel/config/nvmet/subsystems/ssb2 /sys/kernel/config/nvmet/ports/1/subsystems/ssb2

echo -n "Checking if port is listening..."
dmesg | grep "enabling port" && echo "Found" || echo "Not Found"
