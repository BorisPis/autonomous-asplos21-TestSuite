fontsize=18
set terminal postscript eps color fontsize
set output 'breakdown_crc2.eps'

#set datafile separator ","

#-------------------------------------------------------------------------------
# multiplot
#-------------------------------------------------------------------------------
xsiz=.22
xoff=.03
xnum=6
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
set grid y
set xtics rotate by -50
set xtics ('128' 0, '1Ki' 1, '8Ki' 2);
set xrange [-.75:2.75]

#-------------------------------------------------------------------------------
# margins
#-------------------------------------------------------------------------------
set tmargin 2
set bmargin 3.5
set lmargin 6
set rmargin 1

#-------------------------------------------------------------------------------
# style
#-------------------------------------------------------------------------------
set boxwidth .75 relative
set style fill solid .6 border -1
set style histogram rowstacked
set style data histograms

# lc overwrites lt; ps/pt are meaningless for bars
t=1; set style line t lt 1 lw 1 pt t ps 1 lc rgb 'gray80'
t=2; set style line t lt 1 lw 1 pt t ps 1 lc rgb 'dark-violet';
t=3; set style line t lt 1 lw 1 pt t ps 1 lc rgb 'light-green';
t=4; set style line t lt -1 lw 5 pt t ps 1
t=5; set style line t lt -1 lw 5 pt 1 ps 1
t=6; set style line t lt -1 lw 5 pt 2 ps 1

#-------------------------------------------------------------------------------
# labels + key
#-------------------------------------------------------------------------------
set label 1 at screen 0.02, screen (yoff+ysiz*ynum/2) center \
    rotate "cycles"
set label 2 at screen (xoff+xsiz*xnum/2), screen .07 center \
    'I/O depth' 
set key at screen 0, 0.005 Left left bottom \
    samplen 2 spacing .9 width -15 reverse \
    maxrows 3

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
all      (cycall,cyccpy,cyccrc,iops)     = (cycall / iops)
other    (cycall,cyccpy,cyccrc,iops)     = (cycall - cyccpy - cyccrc) / iops;
copy     (cycall,cyccpy,cyccrc,iops)     = (cyccpy / iops);
crc      (cycall,cyccpy,cyccrc,iops)     = (cyccrc / iops);
allplus  (cycall,cyccpy,cyccrc,iops,yhi) = (cycall / iops) + .10*yhi;               	# plus for labe
allmnus  (cycall,cyccpy,cyccrc,iops,yhi) = (cycall - cyccpy - cyccrc) / iops - .08*yhi; # mnus for label
cpy_prcnt(cycall,cyccpy,cyccrc)     = (cyccpy / cycall) * 100.0
crc_prcnt(cycall,cyccpy,cyccrc)     = (cyccrc / cycall) * 100.0

msurdmnus(cycall,yhi) = cycall - .08*yhi; # minus for label
msuredpct(cycall,cyccpy)     = \
	-100 * (1 - msurd(cycall,cyccpy) / other(cycall,cyccpy));
msuredpct2(cycallc,cyccpyc,cycallz,cyccpyz)     = -100 * (1 - other(cycallz, cyccpyz) / other(cycallc, cyccpyc));


ylabfontsiz = fontsize*.8; 
labstr(str) = sprintf("{/=%.0f %.0f}",ylabfontsiz, str);


#-------------------------------------------------------------------------------
# arrays -- one entry per plot
#-------------------------------------------------------------------------------
arr_ids = "4k 16k 64k 256k 1m 4m";
#my_yhi = "60 80 210 600 2250 9000";

# 4        30.11    31.21    31.42    33.35
# 16       39.82    44.43    53.57    57.79
# 64       78.34    95.97   126.29   141.07
# 256     239.99   296.22   410.41   472.32
# 1024    835.10  1087.90  1546.50  1782.55
# 4096   3362.81  4388.90  6279.97  7315.14
arr_other =       "30     39     77     240    830   3300"; 
arr_other2 =      "30     39     77     300    1080  4300"; 
arr_other3 =      "30     57     141    410    1530  6179"; 
arr_other4 =      "30     57     141    472    1750  7142"; 



#-------------------------------------------------------------------------------
# plot
#-------------------------------------------------------------------------------
do for [k=1:6] {

    i=(k-1); j=0;
    set origin (xoff+i*xsiz),(yoff+j*ysiz)
    
    id = word(arr_ids, k);

    mytitle = toupper(id)."iB"
    set title mytitle offset 0,-.5
    
    # defines the STATS_min_y variable
    #stats sprintf("breakdown.%s.csv",id) u 0:(other($6,$5)) nooutput;
    #min_other = STATS_min_y;
    min_other = word(arr_other,k);    # where the first ytic will appear
    min_other2 = word(arr_other2,k);    # where the first ytic will appear
    min_other3 = word(arr_other3,k);    # where the first ytic will appear
    min_other4 = word(arr_other4,k);    # where the first ytic will appear
    yhi0      = min_other * 2.6;      # top end of yrange

    cutoff=500; # when to move from K-s to M-s
    yticsuffix = (min_other < cutoff) ? "K" : "M";
    norma(cyc) = (min_other < cutoff) ? cyc+0 : cyc/1000.0;
    yticfmt    = (min_other < cutoff) ? "%.0f" : "%.1f";

    yic        = sprintf(yticfmt, norma(min_other));
    yic2       = sprintf(yticfmt, norma(min_other2));
    yic3       = sprintf(yticfmt, norma(min_other3));
    yic4       = sprintf(yticfmt, norma(min_other4));
    yhi        = sprintf(yticfmt, norma(yhi0));
    
    if( yhi > 0 ) {set yrange [0:yhi]} else {set yrange [0:*]}
    if( yic > 0 ) {set ytics (yic.yticsuffix yic, yic2.yticsuffix  yic2, yic3.yticsuffix  yic3, yic4.yticsuffix  yic4)  } else {set ytics autofr}

    set ytics format "%g".yticsuffix offset .25,0

    plot sprintf("breakdown2.%s.csv",id) \
       u   (norma(    other($4,$2,$3,$8    )))  ls 1   t 'other'            , \
    '' u   (norma(     copy($4,$2,$3,$8    )))  ls 2   t 'copy'         , \
    '' u   (norma(      crc($4,$2,$3,$8    )))  ls 3   t 'crc'         , \
    '' u 0:(norma(  allmnus($4,$2,$3,$8,yhi0))):(labstr(cpy_prcnt($4,$2,$3)))                   \
                                          ls 4 not            w labels, \
    '' u 0:(norma(  allplus($4,$2,$3,$8,yhi0))):(labstr(crc_prcnt($4,$2,$3)))                   \
                                          ls 4 not            w labels, \
    '' u 0:(norma(      all($5,$2,$3,$9)))      ls 4   t 'measured no copy' w linesp, \
    '' u 0:(norma(      all($6,$2,$3,$10)))      ls 5   t 'measured no crc' w linesp, \
    '' u 0:(norma(      all($7,$2,$3,$11)))      ls 6   t 'measured no crc no copy' w linesp, \

    #'' u 0:(norma(msurdmnus($8,yhi0))):(labstr(msuredpct2($16, $17, $6, $5)))     \
    #                                      ls 4   not          w labels
    
    set ytics autofreq
    set yrange [*:*]
    unset label 1
    unset label 2
    unset key
}
