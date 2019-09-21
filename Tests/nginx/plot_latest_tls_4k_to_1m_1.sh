#!/bin/bash
./plot.sh $TBASE/Results/20_06_13_23.18.28/
gnuplot nginx4b_tls.gp
gnuplot nginx3b_tls.gp
