fontsize=18
set terminal postscript eps color enhanced fontsize;
set output 'tx_drops.eps'

#set datafile separator ","

#-------------------------------------------------------------------------------
# multiplot
#-------------------------------------------------------------------------------
xsiz=.32
xoff=.03
xnum=2
xall=xoff+xnum*xsiz

ysiz=.5
yoff=.06
ynum=1
yall=yoff+ynum*ysiz

set size xall,yall
set multiplot
set size xsiz,ysiz

#-------------------------------------------------------------------------------
# axes
#-------------------------------------------------------------------------------
set grid y lw .01
#set xtics rotate by -50
#set xtics ('2Ki' 1, '4Ki' 2, '8Ki' 3, '16Ki' 4);
set xrange [-.25:5.25]
set xtics 1

#-------------------------------------------------------------------------------
# margins
#-------------------------------------------------------------------------------
set tmargin 3
set bmargin 3.5
set lmargin 4
set rmargin 1

#-------------------------------------------------------------------------------
# style
#-------------------------------------------------------------------------------

# lc overwrites lt; ps/pt are meaningless for bars
t=1; set style line t lt 1 lw 2 ps 2;
t=2; set style line t lt 2 lw 2 ps 2;
t=3; set style line t lt 3 lw 2 ps 2;
#t=1; set style line t lt 1 lw 2 pt t ps 2;
#t=2; set style line t lt 2 lw 2 pt t ps 2;
#t=3; set style line t lt 3 lw 2 pt t ps 2;

#-------------------------------------------------------------------------------
# labels + key
#-------------------------------------------------------------------------------
#set label 1 at screen xoff+0.01, screen (yoff+ysiz*ynum/2) center \
#    rotate "throughput [Gbps]"
#set label 2 at screen (xoff+xsiz), screen (yoff+ysiz*ynum/2) center \
#    rotate "PCIe overhead [%]"
set label 1 at screen (xsiz-0.1), screen .09 center \
    'packet drop rate [%]' 
set label 2 at screen (xsiz*xnum-0.1), screen .09 center \
    'packet drop rate [%]' 
set key at screen xoff-0.02, -0.002 Left left bottom \
    samplen 2 spacing 2.9 width 0 reverse \
    maxrows 1

#-------------------------------------------------------------------------------
# uppercase/lowercase functions (general purpose)
#-------------------------------------------------------------------------------

# Index lookup table strings
UCases="ABCDEFGHIJKLMNOPQRSTUVWXYZ"
LCases="abcdefghijklmnopqrstuvwxyz"

# Convert a single character
toupperchr(c)=substr( UCases.c, strstrt(LCases.c, c), strstrt(LCases.c, c) )
tolowerchr(c)=substr( LCases.c, strstrt(UCases.c, c), strstrt(UCases.c, c) )

# Convert whole strings
toupper(s) = s eq ""  ?  ""  :  toupperchr(s[1:1]).toupper(s[2:*])
tolower(s) = s eq ""  ?  ""  :  tolowerchr(s[1:1]).tolower(s[2:*])

#-------------------------------------------------------------------------------
# data functions
#-------------------------------------------------------------------------------

ylabfontsiz = fontsize*.8; 
labstr(str) = sprintf("{/=%.2f %.2f}",ylabfontsiz, str);
tobw(bw)    = (bw / 1024.0 / 1024.0 / 1024.0);
tobwplus(bw,yhi)    = (bw / 1024.0 / 1024.0 / 1024.0) + yhi;
# pcie gen3 x16 - 100Gbps NIC - https://en.wikipedia.org/wiki/PCI_Express
# 15.75GB/s using 128/130 encoding
topcie_util(bw) = (bw / (15.75 * 8 * 128 / 130.0 * (10**9))) * 100.0

#-------------------------------------------------------------------------------
# plot
#-------------------------------------------------------------------------------
    i=0; j=0;
    set origin (xoff+i*xsiz),(yoff+j*ysiz)
    
    yhi = 5.5
    xhi = 0.4
    set yrange[0:*]
    set title "\n(a) throughput [Gbps]" offset 0,-.5

    set ytics format "%g" offset .25,0
#    plot "model.tcp.csv" \
#       u   ($2):(tobw($4)):(tobw($10))  w yerrorbars ls 1   t 'tcp'            , \
#    "" \
#       u   ($2):(tobw($4))              w lines ls 1   not                  , \
#    'model.tls.offload.csv' \
#       u   ($2):(tobw($4)):(tobw($10))  w yerrorbars ls 2   t 'tls-offload'    , \
#    "" \
#       u   ($2):(tobw($4))              w lines ls 2   not                  , \
#    "" every 2:2:2 \
#       u   ($2+xhi):(tobwplus($4,yhi)):(labstr(tobw($17)/tobw($4)))              w labels not                  , \
#    'model.tls.csv' \
#       u   ($2):(tobw($4)):(tobw($10))  w yerrorbars ls 3   t 'tls'            , \
#    "" \
#       u   ($2):(tobw($4))              w lines ls 3   not                  , \

    set ytics 10
    plot "model.tcp.csv" \
       u   ($2):(tobw($4)):(tobw($10))  w yerrorbars ls 1   t 'tcp'            , \
    "" \
       u   ($2):(tobw($4))              w lines ls 1   not                  , \
    'model.tls.offload.csv' \
       u   ($2):(tobw($4)):(tobw($10))  w yerrorbars ls 2   t 'tls-offload'    , \
    "" \
       u   ($2):(tobw($4))              w lines ls 2   not                  , \
    "" every 2:2:1 \
       u   ($2+xhi):(tobwplus($4,yhi)):(labstr(tobw($4)/tobw($15)))              w labels not                  , \
    'model.tls.csv' \
       u   ($2):(tobw($4)):(tobw($10))  w yerrorbars ls 3   t 'tls'            , \
    "" \
       u   ($2):(tobw($4))              w lines ls 3   not                  , \

    
    set ytics autofreq
    set yrange [*:*]
    unset label 1
    unset label 2
    unset label 3
    unset key
#-------------------------------------------------------------------------------
    i=1; j=0;
    set origin (xoff+i*xsiz),(yoff+j*ysiz)
    
    set yrange[0:*]
    set title "(b) context recovery\nPCIe overhead [%]" offset 0,-.5

    plot "model.tls.offload.csv" \
       u   ($2):(topcie_util($3)):(topcie_util(9))  w yerrorbars ls 2   not ,\
    "" \
       u   ($2):(topcie_util($3))              w lines ls 2   not                  , \

