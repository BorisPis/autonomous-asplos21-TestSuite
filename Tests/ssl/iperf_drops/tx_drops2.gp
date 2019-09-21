fontsize=18
smallfont=16
set terminal postscript eps color enhanced fontsize;
set output 'tx_drops2.eps'

#set datafile separator ","

#-------------------------------------------------------------------------------
# multiplot
#-------------------------------------------------------------------------------
xsiz=.35
xoff=.00
xnum=2
xall=xoff+xnum*xsiz

ysiz=.44
yoff=.06
ynum=1
yall=yoff+ynum*ysiz

set size xall,yall
set multiplot
set size xsiz,ysiz

#-------------------------------------------------------------------------------
# axes and such
#-------------------------------------------------------------------------------
set grid y my lc 'gray'; # lw .01
set xrange [-.5:5.5]
set key samplen 2 spacing .9 width -1 top right 
set label 1  "packet drop rate [%]" at screen (xoff+xsiz), screen 0.02 center

#-------------------------------------------------------------------------------
# margins
#-------------------------------------------------------------------------------
set tmargin 1.7
set bmargin 1.5
set lmargin 6
set rmargin 1

#-------------------------------------------------------------------------------
# style
#-------------------------------------------------------------------------------

set style data linespoints
w=5; p=1.3
t=1; set style line t lt 1 lw w ps p    pt 4;
t=2; set style line t lt 2 lw w ps p    pt 3;
t=3; set style line t lt 3 lw w ps p+.2 pt 1;

#-------------------------------------------------------------------------------
# throughput
#-------------------------------------------------------------------------------
i=0; j=0;
set origin (xoff+i*xsiz),(yoff+j*ysiz)
set title "(a) throughput" offset 0,-.5
set logscale y 2
set yrange [:96]
set ylabel "Gbps" offset .75,0
tobw(bw) = (bw / 1024.0 / 1024.0 / 1024.0);
plot \
"model.tcp.csv"         u 2:(tobw($4)) ls 1 t 'tcp' , \
'model.tls.offload.csv' u 2:(tobw($4)) ls 2 t 'offload' , \
'model.tls.csv'         u 2:(tobw($4)) ls 3 t 'tls', \
'model.tls.offload.csv' every 2:2:1 \
    u 2:(tobw($4)):(sprintf("%.1f",$4/$15)) w labels \
    offset .3,1.2 rotate by 30 font ",".smallfont not

unset label 1
set yrange [*:*]
unset logscale
set ytics autofreq
unset key

#-------------------------------------------------------------------------------
# PCIe overhead
#-------------------------------------------------------------------------------
i=1; j=0;
set origin (xoff+i*xsiz),(yoff+j*ysiz)
set ylabel "% of total"
set ytics 1
set mytics 2
set title "(b) PCIe overhead" offset 0,-.5

# pcie gen3 x16 - 100Gbps NIC - https://en.wikipedia.org/wiki/PCI_Express
# 15.75GB/s using 128/130 encoding
topcie_util(bw) = (bw / (15.75 * 8 * 128 / 130.0 * (10**9))) * 100.0

plot "model.tls.offload.csv" u 2:(topcie_util($3)) ls 2 not
