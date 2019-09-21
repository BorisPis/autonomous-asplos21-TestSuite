fontsize=18
xticfont=18
set terminal postscript eps color enhanced fontsize;
set output 'breakdown.eps'

#set datafile separator ","

#-------------------------------------------------------------------------------
# multiplot
#-------------------------------------------------------------------------------
xsiz=.32
xoff=.03
xof2=.02; # for the right y label
xnum=2
xall=xoff+xnum*xsiz+xof2

ysiz=.4
yoff=.11
ynum=1
yall=yoff+ynum*ysiz
print xall, yall

set size xall,yall
set multiplot
set size xsiz,ysiz

#-------------------------------------------------------------------------------
# axes
#-------------------------------------------------------------------------------
set logscale x 2
set grid front 
set xtics 4 font ",".xticfont rotate  \
  (1, 4, 16, 64, 256, '1Ki' 1024, '4Ki' 4096)
set xrange [*:4096]
set ytics  format "%gK"  offset  .5,0 
set y2tics format "%g%%" offset -.6,0 
set yrange [0:*];
set y2range [0:*];

#-------------------------------------------------------------------------------
# margins
#-------------------------------------------------------------------------------
set tmargin 1.5
set bmargin 2.2
set lmargin 5
set rmargin 5

#-------------------------------------------------------------------------------
# style
#-------------------------------------------------------------------------------

set style data filledcurve x1

# set boxwidth .75 relative
# set style fill solid .6 border -1
# set style histogram rowstacked
# set style data histograms

# lc overwrites lt; ps/pt are meaningless for bars
w=5; p=1.5;
t=1; set style line t lt  1 lw w pt t ps p lc rgb 'gray90';      # idle
t=2; set style line t lt  2 lw w pt t ps p lc rgb 'gray70';      # other
t=3; set style line t lt  3 lw w pt t ps p lc rgb 'light-green'; # copy
t=4; set style line t lt  4 lw w pt t ps p lc rgb 'purple';      # crc
t=5; set style line t lt -1 lw w pt 1 ps p
t=6; set style line t lt  1 lw w pt t ps p

#-------------------------------------------------------------------------------
# labels + key
#-------------------------------------------------------------------------------
set label 1 at screen 0.015, screen (yoff+ysiz*ynum/2+.02) center \
    rotate "cycles per request"
set label 3 at screen xall-0.015, screen (yoff+ysiz*ynum/2+.02) center \
    rotate "difference"
set label 2 at screen (xoff+xsiz*xnum/2), screen .08 center \
    'I/O depth' 

# set key top right  samplen 0.5 spacing .8 reverse maxrows 3 Left
# set key at screen xoff+0.045, screen ysiz Left left top 

set key at screen 0.02, screen 0.003 Left left bottom \
    samplen 2 spacing .95 reverse maxrows 1 invert


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
all (all,cpy,crc,iops,cpu) = (all / iops)
idl (all,cpy,crc,iops,cpu) = (all / iops) * (1 - cpu);       # idl = idle
otr (all,cpy,crc,iops,cpu) = (all * cpu - cpy - crc) / iops; # otr = other
cpy (all,cpy,crc,iops,cpu) = (cpy / iops);
crc (all,cpy,crc,iops,cpu) = (crc / iops);
off (all,cpy,crc,iops,cpu) = (crc+cpy) / iops;
cpyP(all,cpy,crc,iops,cpu) = (cpy / all)       * cpu * 100.0; # P = percent
crcP(all,cpy,crc,iops,cpu) = (crc / all)       * cpu * 100.0;
offP(all,cpy,crc,iops,cpu) = ((crc+cpy) / all) * cpu * 100.0;

# c = commutative
c_idl    (all,cpy,crc,iops,cpu) = \
  idl    (all,cpy,crc,iops,cpu)
  
c_otr    (all,cpy,crc,iops,cpu) = \
  c_idl  (all,cpy,crc,iops,cpu) + \
  otr    (all,cpy,crc,iops,cpu)

c_cpy    (all,cpy,crc,iops,cpu) = \
  c_otr  (all,cpy,crc,iops,cpu) + \
  cpy    (all,cpy,crc,iops,cpu)

c_crc    (all,cpy,crc,iops,cpu) = \
  c_cpy  (all,cpy,crc,iops,cpu) + \
  crc    (all,cpy,crc,iops,cpu)

labstr(str) = sprintf("%.0f%%", str);
xt(iod) = iod < 1000 ? sprintf("%.0f",iod) : sprintf("%.0fK",iod/1024.0);



#-------------------------------------------------------------------------------
# arrays -- one entry per plot
#-------------------------------------------------------------------------------
arr_ids    =  "4k   256k"
arr_yhi    =  "100   600"
arr_y1tic  =  "20    100"
arr_y2tic  =  "2      10"


#-------------------------------------------------------------------------------
# plot
#-------------------------------------------------------------------------------
do for [k=1:2] {

    i=(k-1); j=0;
    set origin (xoff+i*xsiz),(yoff+j*ysiz)
    
    id         = word(arr_ids, k);
    yhi        = word(arr_yhi, k);
    y1t        = word(arr_y1tic, k);
    y2t        = word(arr_y2tic, k);
    mytitle    = toupper(id)."iB"
    
    set title mytitle offset 0,-.5

    if( yhi > 0 ) { set yrange [0:yhi] } 
    else          { set yrange [0:*]   }
    if( y1t > 0 ) { set ytics  y1t     }
    if( y2t > 0 ) { set y2tics y2t     }

    plot sprintf("breakdown2.%s.csv",id) \
       u 12:(c_crc($4,$2,$3,$8,$13)) ls 4 t 'crc', \
    '' u 12:(c_cpy($4,$2,$3,$8,$13)) ls 3 t 'copy', \
    '' u 12:(c_otr($4,$2,$3,$8,$13)) ls 2 t 'other', \
    '' u 12:(c_idl($4,$2,$3,$8,$13)) ls 1 t 'idle', \
    '' u 12:( offP($4,$2,$3,$8,$13)) ls 5 t '%' \
       w linesp axes x1y2

    set ytics autofreq
    set y2tics autofreq
    set yrange [*:*]
    unset label 1
    unset label 2
    unset label 3
    unset key
}
