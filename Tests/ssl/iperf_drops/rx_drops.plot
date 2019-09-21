fontsize=18
set terminal postscript eps color enhanced fontsize;
set output 'rx_drops.eps'

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
set tmargin 2
set bmargin 4.5
set lmargin 4
set rmargin 1

#-------------------------------------------------------------------------------
# style
#-------------------------------------------------------------------------------

t=1; set style line t lt 1 lw 2 ps 2;
t=2; set style line t lt 2 lw 2 ps 2;
t=3; set style line t lt 3 lw 2 ps 2;
t=4; set style line t lt 4 lw 2 ps 2;
t=5; set style line t lt 5 lw 2 ps 2;
t=6; set style line t lt 7 lw 2 ps 2;
# lc overwrites lt; ps/pt are meaningless for bars
#t=1; set style line t lt 1 lw 2 pt t ps 2;
#t=2; set style line t lt 2 lw 2 pt t ps 2;
#t=3; set style line t lt 3 lw 2 pt t ps 2;
#t=4; set style line t lt 4 lw 2 pt t ps 2;
#t=5; set style line t lt 5 lw 2 pt t ps 2;
#t=6; set style line t lt 7 lw 2 pt t ps 2;

#-------------------------------------------------------------------------------
# labels + key
#-------------------------------------------------------------------------------
#set label 1 at screen xoff+0.01, screen (yoff+ysiz*ynum/2) center \
#    rotate "throughput [Gbps]"
#set label 2 at screen (xoff+xsiz), screen (yoff+ysiz*ynum/2) center \
#    rotate "PCIe overhead [%]"
set label 1 at screen (xsiz-0.1), screen .15 center \
    'packet drop rate [%]' 
set label 2 at screen (xsiz*xnum-0.1), screen .15 center \
    'packet drop rate [%]' 

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
labstr(str) = sprintf("{/=%.1f %.1f}",ylabfontsiz, str);
tobw(bw)    = (bw / 1024.0 / 1024.0 / 1024.0);
tobwplus(bw,yhi)    = (bw / 1024.0 / 1024.0 / 1024.0) + yhi;
tobwmnus(bw,yhi)    = (bw / 1024.0 / 1024.0 / 1024.0) - yhi;

   full_enc(decrypted,part_dec,encrypted)  = encrypted / (decrypted+part_dec+encrypted) * 100.0;
partial_enc(decrypted,part_dec,encrypted)  = part_dec  / (decrypted+part_dec+encrypted) * 100.0;
  decrypted(decrypted,part_dec,encrypted)  = decrypted / (decrypted+part_dec+encrypted) * 100.0;

#-------------------------------------------------------------------------------
# plot
#-------------------------------------------------------------------------------
    i=0; j=0;
    set origin (xoff+i*xsiz),(yoff+j*ysiz)
    
    yhi=1.6
    xhi = 0.3
    set yrange[0:17]
    set title "(a) throughput [Gbps]" offset 0,-.5
    set key at screen xoff+0.04, -0.002 Left left bottom \
        samplen 2 spacing 2.9 width 0 reverse \
        horizontal maxrows 1

    set ytics format "%g" offset .25,0
    set ytics 05
    plot "model.tcp.csv" \
       u   ($2):(tobw($5)):(tobw($11))  w errorbars ls 1   t 'tcp'            , \
    "" \
       u   ($2):(tobw($5))              w lines ls 1   not                  , \
    "" every 2:2:1 \
       u   ($2+xhi):(tobwplus($5,yhi)):(labstr(tobw($5)/tobw($16)))              w labels not                  , \
    'model.tls.offload.csv' \
       u   ($2):(tobw($5)):(tobw($11))  w errorbars ls 2   t 'tls-offload'    , \
    "" \
       u   ($2):(tobw($5))              w lines ls 2   not                  , \
    "" every 2:2:1 \
       u   ($2+xhi):(tobwmnus($16,yhi)):(labstr(tobw($5)/tobw($16)))              w labels not                  , \
    'model.tls.csv' \
       u   ($2):(tobw($5)):(tobw($11))  w errorbars ls 3   t 'tls'            , \
    "" \
       u   ($2):(tobw($5))              w lines ls 3   not                  , \
    
    set ytics autofreq
    set yrange [*:*]
    unset label 1
    unset label 2
    unset label 3
    unset key
#-------------------------------------------------------------------------------
    i=1; j=0;
    set origin (xoff+i*xsiz),(yoff+j*ysiz)
    set yrange[0:100]
    set ytics 20
    set xrange[.25:11.75]
    set xtics ('0' 1, '' 2, '1' 3, '' 4, '2' 5, '' 6, '3' 7, '' 8, '4' 9, '' 10, '5' 11);

    set title "(b) TLS records [%]" offset 0,-.5
    
#### style
    set boxwidth .75 relative
    set style fill solid .6 border -1
    set style histogram rowstacked
    set style data histograms

#### key
    set key at screen xall-xoff-0.24, -0.002 Left left bottom \
        samplen 2 spacing 2.9 width .5 reverse invert \
        horizontal maxrows 1

#XXX: We can add errorbars here too - https://stackoverflow.com/questions/22548952/gnuplot-row-stacked-bar-graph-with-error-bar
    plot "model.tls.offload.csv" \
       u     (  decrypted($6,$7,$8))  ls 1   t 'offloaded', \
    '' u     (partial_enc($6,$7,$8))  ls 2   t 'partially offloaded'    , \
    '' u     (   full_enc($6,$7,$8))  ls 3   t 'not offloaded'
    #plot "model.tls.offload.csv" \
    #   u     (partial_enc($6,$7,$8))  ls 4   t 'partially encrypted', \
    #'' u     (   full_enc($6,$7,$8))  ls 5   t 'fully encrypted'    , \
    #'' u     (  decrypted($6,$7,$8))  ls 6   t 'decrypted'

    unset key
