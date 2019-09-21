#!/bin/bash

DDGST="-G"
echo dip1=$dip1
[ -z "$dip1" ] && exit
[ -z "$QUEUES" ] && exit
[ -z "$PORT" ] && PORT=4420
[ -z "$NODC" ] && echo disconnecting && sudo nvme disconnect-all /dev/nvme0
[ -z "$CRC" ] && DDGST=""
[ -z "$DEPTH" ] && DEPTH=1024

#sudo modprobe -vr nvme_tcp
sudo modprobe -v nvme_tcp

# for making both devices on the same client CPU and different server CPUs
echo "sudo nvme connect-all -t tcp -a $dip1 -s $PORT $DDGST --nr-io-queues=$QUEUES --hostnqn=myhostnqn "
sudo nvme connect-all -t tcp -a $dip1 -s $PORT $DDGST --nr-io-queues=$QUEUES --hostnqn=myhostnqn --queue-size=$DEPTH --nr-poll-queues=$[$QUEUES/3] --nr-write-queues=$[$QUEUES/3]
#sudo nvme connect-all -t tcp -a $dip1 -s $PORT $DDGST --nr-io-queues=$[28*3] --hostnqn=myhostnqn --queue-size=1024 --nr-poll-queues=$QUEUES

## for making both devices on the same server CPU (server has 12 cores)
#echo "sudo nvme connect-all -t tcp -a $dip1 -s $PORT --nr-io-queues=13"
#sudo nvme connect-all -t tcp -a $dip1 -s $PORT --nr-io-queues=13

sudo chmod 666 /dev/nvme*
