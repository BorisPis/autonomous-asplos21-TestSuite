fontsize=18
smallfont=16
set terminal postscript eps color enhanced fontsize;
set output 'rx_drops2.eps'

#set datafile separator ","

#-------------------------------------------------------------------------------
# utilities
#-------------------------------------------------------------------------------
labstr(str) = sprintf("{/=%.2f %.2f}",smallfont, str);

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
set label 1  "packet loss rate [%]" at screen (xoff+xsiz), screen 0.10 center

#-------------------------------------------------------------------------------
# margins
#-------------------------------------------------------------------------------
set tmargin 1.7
#set bmargin 1.5
set bmargin 3.5
set lmargin 6
set rmargin 1

#-------------------------------------------------------------------------------
# partial decryption
#-------------------------------------------------------------------------------
i=0; j=0;
set origin (xoff+i*xsiz),(yoff+j*ysiz)
set xrange[.25:11.75]
set xtics ('0' 1, '' 2, '1' 3, '' 4, '2' 5, '' 6, '3' 7, '' 8, '4' 9, '' 10, '5' 11);
set yrange[0:100]
set ytics 20
set ylabel "% of total" offset 1.75,0
set title "(a) TLS records" offset 0,-.5

# key
set key at screen xoff+0.01, -0.003 samplen 2 spacing .9 width -1 Left bottom left reverse

# style
set boxwidth .75 relative
set style fill solid .6 border -1
set style histogram rowstacked
set style data histograms

# utility functions
   full_enc(decrypted,part_dec,encrypted)  = encrypted / (decrypted+part_dec+encrypted) * 100.0;
partial_enc(decrypted,part_dec,encrypted)  = part_dec  / (decrypted+part_dec+encrypted) * 100.0;
  decrypted(decrypted,part_dec,encrypted)  = decrypted / (decrypted+part_dec+encrypted) * 100.0;

plot "model.tls.offload.csv" \
   u     (  decrypted($6,$7,$8))  ls 1   t 'offload', \
'' u     (partial_enc($6,$7,$8))  ls 2   t 'part offload'    , \
'' u     (   full_enc($6,$7,$8))  ls 3   t 'not offload'

unset label 1
set yrange [*:*]
unset logscale
set ytics autofreq
unset key
#unset xtics

#-------------------------------------------------------------------------------
# throughput
#-------------------------------------------------------------------------------
i=1; j=0;
set origin (xoff+i*xsiz),(yoff+j*ysiz)
set title "(b) throughput" offset 0,-.5
set xrange [-.8:5.8]
set xtics 1
set logscale y 2
set yrange [1.5:32]
set ylabel "Gbps [log scale]" offset 1.75,0
tobw(bw) = (bw / 1024.0 / 1024.0 / 1024.0);

# key
set key at screen xall-0.01, 0.003 samplen 2 spacing .9 width -1 Right bottom right

# style
set style data linespoints
w=5; p=1.3
t=1; set style line t lt 1 lw w ps p    pt 4;
t=2; set style line t lt 2 lw w ps p    pt 3;
t=3; set style line t lt 3 lw w ps p+.2 pt 1;

plot \
"model.tcp.csv"          u  2:(tobw($5)):(tobw($11)) ls 1 t 'tcp' , \
""                       u  2:(tobw($5))             ls 1 not     , \
"" every 2:2:1           u  2:(tobw($5)):(labstr($5/$16))  w labels not offset 0.3,0.9 \
                            rotate by 30 font ",".smallfont, \
"model.tls.offload.csv"  u  2:(tobw($5)):(tobw($11)) ls 2 t 'offload'  , \
""                       u  2:(tobw($5))             ls 2 not              , \
"" every 2:2:1           u  2:(tobw($16)):(labstr($5/$16)) w labels not offset 0.3,-0.9 \
                            rotate by 30 font ",".smallfont, \
"model.tls.csv"          u  2:(tobw($5)):(tobw($11)) ls 3 t 'tls' , \
""                       u  2:(tobw($5))             ls 3 not    

#plot \
#"model.tcp.csv"         u 2:(tobw($4)) ls 1 t 'tcp' , \
#'model.tls.offload.csv' u 2:(tobw($4)) ls 2 t 'offload' , \
#'model.tls.csv'         u 2:(tobw($4)) ls 3 t 'tls', \
#'model.tls.offload.csv' every 2:2:1 \
#    u 2:(tobw($4)):(sprintf("%.1f",$4/$15)) w labels \
#    offset .3,1.2 rotate by 30 font ",".smallfont not

unset label 1
set yrange [*:*]
unset logscale
set ytics autofreq
unset key

