#!/bin/bash

echo if1=$if1
[ -z "$if1" ] && exit
#if1=mlx0

echo 0 | sudo tee /sys/kernel/config/nvmet/subsystems/ssb2/namespaces/11/enable
echo 0 | sudo tee /sys/kernel/config/nvmet/subsystems/ssb3/namespaces/12/enable

sudo modprobe -vr null_blk
sudo modprobe -vr nvmet_tcp
sudo modprobe -v nvmet_tcp
sudo modprobe -v null_blk nr_devices=2

# create nvme subsystem ssb2
sudo mkdir /sys/kernel/config/nvmet/subsystems/ssb2
echo 1 | sudo tee /sys/kernel/config/nvmet/subsystems/ssb2/attr_allow_any_host

# create namespace and attach the nvme device to it (assume /dev/nullb0 exists)
sudo mkdir /sys/kernel/config/nvmet/subsystems/ssb2/namespaces/11
echo -n /dev/nullb0 | sudo tee /sys/kernel/config/nvmet/subsystems/ssb2/namespaces/11/device_path
echo 1 | sudo tee /sys/kernel/config/nvmet/subsystems/ssb2/namespaces/11/enable

# create nvme target port on $if1
sudo mkdir /sys/kernel/config/nvmet/ports/1
echo `ip addr show $if1 | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}"` | sudo tee /sys/kernel/config/nvmet/ports/1/addr_traddr
echo tcp | sudo tee /sys/kernel/config/nvmet/ports/1/addr_trtype
echo 4420 | sudo tee /sys/kernel/config/nvmet/ports/1/addr_trsvcid
echo ipv4 | sudo tee /sys/kernel/config/nvmet/ports/1/addr_adrfam

sudo ln -s /sys/kernel/config/nvmet/subsystems/ssb2 /sys/kernel/config/nvmet/ports/1/subsystems/ssb2

# create nvme subsystem ssb3
sudo mkdir /sys/kernel/config/nvmet/subsystems/ssb3
echo 1 | sudo tee /sys/kernel/config/nvmet/subsystems/ssb3/attr_allow_any_host

# create namespace and attach the nvme device to it (assume /dev/nullb1 exists)
sudo mkdir /sys/kernel/config/nvmet/subsystems/ssb3/namespaces/12
echo -n /dev/nullb1 | sudo tee /sys/kernel/config/nvmet/subsystems/ssb3/namespaces/12/device_path
echo 1 | sudo tee /sys/kernel/config/nvmet/subsystems/ssb3/namespaces/12/enable

# create nvme target port on $if1
sudo mkdir /sys/kernel/config/nvmet/ports/1
echo `ip addr show $if1 | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}"` | sudo tee /sys/kernel/config/nvmet/ports/1/addr_traddr
echo tcp | sudo tee /sys/kernel/config/nvmet/ports/1/addr_trtype
echo 4420 | sudo tee /sys/kernel/config/nvmet/ports/1/addr_trsvcid
echo ipv4 | sudo tee /sys/kernel/config/nvmet/ports/1/addr_adrfam

sudo ln -s /sys/kernel/config/nvmet/subsystems/ssb3 /sys/kernel/config/nvmet/ports/1/subsystems/ssb3

echo -n "Checking if port is listening..."
dmesg | grep "enabling port" && echo "Found" || echo "Not Found"

# disable merging
echo 2 | sudo tee /sys/block/nullb0/queue/nomerges
echo 2 | sudo tee /sys/block/nullb1/queue/nomerges

# increase segments
echo 65535 | sudo tee /sys/block/nullb0/queue/max_segments
echo 65535 | sudo tee /sys/block/nullb1/queue/max_segments

# increase max_sectors_kb
echo 2560 | sudo tee /sys/block/nullb0/queue/max_sectors_kb
echo 2560 | sudo tee /sys/block/nullb1/queue/max_sectors_kb

# no io scheduler
echo none | sudo tee /sys/block/nullb0/queue/scheduler
echo none | sudo tee /sys/block/nullb1/queue/scheduler
