fontsize=18
smallfont=14
set terminal postscript eps color enhanced fontsize;
set output 'rx_drops2b.eps'

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
set label 1  "packet loss rate [%]" at screen (xoff+xsiz), screen 0.02 center

#-------------------------------------------------------------------------------
# margins
#-------------------------------------------------------------------------------
set tmargin 1.7
set bmargin 1.5
set lmargin 6
set rmargin 1



#-------------------------------------------------------------------------------
# throughput
#-------------------------------------------------------------------------------
i=0; j=0;
set origin (xoff+i*xsiz),(yoff+j*ysiz)
set title "(a) throughput" offset 0,-.5
set xrange [-.8:5.8]
set xtics 1 scale 0
set logscale y 2
set yrange [1.5:96]
set ylabel "Gbps [log scale]" offset .75,0
tobw(bw) = (bw / 1024.0 / 1024.0 / 1024.0);
set key notitle nobox noopaque top right Right samplen 2 spacing .85 width -1

# style
set style data linespoints
w=5; p=1.3
t=1; set style line t lt 1 lw w ps p    pt 4;
t=2; set style line t lt 2 lw w ps p    pt 3;
t=3; set style line t lt 3 lw w ps p+.2 pt 1;

lstr(y1,y2) = (y1/y2 > 2) \
            ? sprintf("%.1fx", y1/y2) \
	    : sprintf("%.0f%%", 100*y1/y2 - 100)

# 1st labels = offload/tls
# 2nd labels = offload/tcp
plot \
"model.tcp.csv"         u 2:(tobw($5)) ls 1 t 'tcp' , \
'model.tls.offload.csv' u 2:(tobw($5)) ls 2 t 'offload' , \
'model.tls.csv'         u 2:(tobw($5)) ls 3 t 'tls', \
'model.tls.offload.csv' every 2:2:1 \
    u 2:(tobw($16)):(lstr($5,$16)) w labels \
    offset .3,-1.1 rotate by 45 textcolor 'grey40' font ",".smallfont not, \
'model.tls.offload.csv' every 2:2:1 \
    u 2:(tobw($18)):(lstr($5,$18)) w labels \
    offset .3,1.2 rotate by 45 textcolor 'grey40' font ",".smallfont not 


unset label 1
set yrange [*:*]
unset logscale
set ytics autofreq
unset key


#-------------------------------------------------------------------------------
# partial decryption
#-------------------------------------------------------------------------------
i=1; j=0;
set origin (xoff+i*xsiz),(yoff+j*ysiz)
set xrange[.25:11.75]
set xtics \
  ('0' 1, '' 2, '1' 3, '' 4, '2' 5, '' 6, '3' 7, '' 8, '4' 9, '' 10, '5' 11);
set yrange[0:100]
set ytics 20
set ylabel "% of total" offset 2,0;
set title "(b) TLS records" offset 0,-.5

set key bottom left Left reverse invert samplen 1 spacing 1.0 width -3 \
   box opaque title 'offloaded?' 

# style
set style data linespoints
w=1; p=1.3
t=1; set style line t lt 1 lw w ps p    pt 4;
t=2; set style line t lt 2 lw w ps p    pt 3;
t=3; set style line t lt 3 lw w ps p+.2 pt 1;

# style
set boxwidth .75 relative
set style fill solid .6 border -1
set style histogram rowstacked
set style data histograms

# utility functions
full_enc(decrypted,part_dec,encrypted) = \
  encrypted / (decrypted+part_dec+encrypted) * 100.0;
partial_enc(decrypted,part_dec,encrypted) = \
  part_dec  / (decrypted+part_dec+encrypted) * 100.0;
decrypted(decrypted,part_dec,encrypted) = \
  decrypted / (decrypted+part_dec+encrypted) * 100.0;

plot "model.tls.offload.csv" \
   u     (  decrypted($6,$7,$8))  ls 1   t 'entirely', \
'' u     (partial_enc($6,$7,$8))  ls 2   t 'partially'    , \
'' u     (   full_enc($6,$7,$8))  ls 3   t 'no'

unset label 1
unset logscale
set ytics autofreq


