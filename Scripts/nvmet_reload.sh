#!/bin/bash

sudo modprobe -vr null_blk
sudo modprobe -vr nvme_tcp
sudo modprobe -vr nvmet_tcp
sudo modprobe -v nvmet_tcp
sudo modprobe -v nvme_tcp
sudo modprobe -v null_blk nr_devices=1

# create nvme subsystem ssb
sudo mkdir /sys/kernel/config/nvmet/subsystems/ssb
echo 1 | sudo tee /sys/kernel/config/nvmet/subsystems/ssb/attr_allow_any_host

# create nvme subsystem ssb2
sudo mkdir /sys/kernel/config/nvmet/subsystems/ssb2
echo 1 | sudo tee /sys/kernel/config/nvmet/subsystems/ssb2/attr_allow_any_host

# create namespace and attach the nvme device to it (assume /dev/nvme0n1 exists)
sudo mkdir /sys/kernel/config/nvmet/subsystems/ssb/namespaces/10
echo -n /dev/nvme0n1 | sudo tee /sys/kernel/config/nvmet/subsystems/ssb/namespaces/10/device_path
echo 1 | sudo tee /sys/kernel/config/nvmet/subsystems/ssb/namespaces/10/enable

# create namespace and attach the nvme device to it (assume /dev/nullb0 exists)
sudo mkdir /sys/kernel/config/nvmet/subsystems/ssb2/namespaces/11
echo -n /dev/nullb0 | sudo tee /sys/kernel/config/nvmet/subsystems/ssb2/namespaces/11/device_path
echo 1 | sudo tee /sys/kernel/config/nvmet/subsystems/ssb2/namespaces/11/enable

# create nvme target port on mlx0
sudo mkdir /sys/kernel/config/nvmet/ports/1
echo `ip addr show mlx0 | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}"` | sudo tee /sys/kernel/config/nvmet/ports/1/addr_traddr
echo tcp | sudo tee /sys/kernel/config/nvmet/ports/1/addr_trtype
echo 4420 | sudo tee /sys/kernel/config/nvmet/ports/1/addr_trsvcid
echo ipv4 | sudo tee /sys/kernel/config/nvmet/ports/1/addr_adrfam

sudo ln -s /sys/kernel/config/nvmet/subsystems/ssb /sys/kernel/config/nvmet/ports/1/subsystems/ssb
sudo ln -s /sys/kernel/config/nvmet/subsystems/ssb2 /sys/kernel/config/nvmet/ports/1/subsystems/ssb2
echo -n "Checking if port is listening..."
dmesg | grep "enabling port" && echo "Found" || echo "Not Found"

# disable merging
echo 2 | sudo tee /sys/block/nullb0/queue/nomerges

