#!/bin/bash

function add_comma_every_eight
{
        echo " $1 " | sed -r ':L;s=\b([0-9]+)([0-9]{8})\b=\1,\2=g;t L'
}

function int2hex
{
	CHUNKS=$(( $1/64 ))
	COREID=$1
	HEX=""
 	for (( CHUNK=0; CHUNK<${CHUNKS} ; CHUNK++ ))
	do
		HEX=$HEX"0000000000000000"
		COREID=$((COREID-64))
	done
        printf "%x$HEX" $(echo $((2**$COREID)) )
}


function core_to_affinity
{
	echo $( add_comma_every_eight $( int2hex $1) )
}

function get_irq_list
{
	interface=$1
	infiniband_device_irqs_path="/sys/class/infiniband/$interface/device/msi_irqs"
	net_device_irqs_path="/sys/class/net/$interface/device/msi_irqs"
	interface_in_proc_interrupts=$( cat /proc/interrupts | egrep "$interface[^0-9,a-z,A-Z]" | awk '{print $1}' | sed 's/://' )
	if [ -d $infiniband_device_irqs_path ]; then
		irq_list=$( /bin/ls $infiniband_device_irqs_path )
	elif [ "$interface_in_proc_interrupts" != "" ]; then
		irq_list=$interface_in_proc_interrupts
	elif [ -d $net_device_irqs_path ]; then
		irq_list=$( /bin/ls $net_device_irqs_path )
	else 
		echo "Error - interface or device \"$interface\" does not exist" 1>&2
		exit 1
	fi
	echo $irq_list
}

function show_irq_affinity
{
	irq_num=$1
	smp_affinity_path="/proc/irq/$irq_num/smp_affinity"
        if [ -f $smp_affinity_path ]; then
                echo -n "$irq_num: "
                cat $smp_affinity_path
        fi
}

function set_irq_affinity
{
	irq_num=$1
	affinity_mask=$2
	smp_affinity_path="/proc/irq/$irq_num/smp_affinity"
        if [ -f $smp_affinity_path ]; then
                echo $affinity_mask | sudo tee $smp_affinity_path
        fi
}

function is_affinity_hint_set
{
	irq_num=$1
	hint_not_set=0
	affinity_hint_path="/proc/irq/$irq_num/affinity_hint"
	if [ -f $affinity_hint_path ]; then
		TOTAL_CHAR=$( wc -c < $affinity_hint_path  )
		NUM_OF_COMMAS=$( grep -o "," $affinity_hint_path | wc -l )
		NUM_OF_ZERO=$( grep -o "0" $affinity_hint_path | wc -l )
		NUM_OF_F=$( grep -i -o "f" $affinity_hint_path | wc -l )
		if [[ $((TOTAL_CHAR-1-NUM_OF_COMMAS)) -eq $NUM_OF_ZERO || $((TOTAL_CHAR-1-NUM_OF_COMMAS)) -eq $NUM_OF_F ]]; then
			hint_not_set=1
		fi
	else
		hint_not_set=1
	fi
	return $hint_not_set
}
