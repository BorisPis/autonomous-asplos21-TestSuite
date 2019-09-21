#!/bin/bash

SUITE=$TBASE/TestSuite/

while [ 1 ]
do
	$SUITE/Scripts/drop_vm_cache.sh
	sleep 1
done
