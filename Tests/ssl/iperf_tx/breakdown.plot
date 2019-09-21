fontsize=18
set terminal postscript eps color enhanced fontsize;
set output 'breakdown.eps'

#set datafile separator ","

#-------------------------------------------------------------------------------
# multiplot
#-------------------------------------------------------------------------------
xsiz=.32
xoff=.03
xnum=2
xall=xoff+xnum*xsiz

ysiz=.4
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
set xtics ('2' 1, '4' 2, '8' 3, '16' 4) nomirror;
set xrange [.25:4.75]

#-------------------------------------------------------------------------------
# margins
#-------------------------------------------------------------------------------
set tmargin 2
set bmargin 2.8
set lmargin 5
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
t=4; set style line t lt -1 lw 5 pt t ps 2
t=5; set style line t lt -1 lw 5 pt 1 ps 2
t=6; set style line t lt -1 lw 5 pt 2 ps 2

#-------------------------------------------------------------------------------
# labels + key
#-------------------------------------------------------------------------------
set label 1 at screen 0.02, screen (yoff+ysiz*ynum/2+0.02) center \
    rotate "cycles per record"
set label 2 at screen (xoff+xsiz*xnum/2), screen .07 center \
    'TLS record size [KiB]' 
set key at screen (xall/4), -0.030 Left left bottom \
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
iops     (recsz, thpt)                = thpt / 8.0 / recsz * 1000.0 * 1000.0 * 1000.0
all      (recsz,enccy,opcyc,thpt)     = (opcyc) / iops(recsz,thpt)
other    (recsz,enccy,opcyc,thpt)     = (opcyc - enccy) / iops(recsz,thpt);
enc      (recsz,enccy,opcyc,thpt)     = (enccy) / iops(recsz,thpt);

allplus  (recsz,enccy,opcyc,thpt,yhi) = (opcyc / iops(recsz,thpt)) + .10*yhi;               	# plus for labe
enc_prcnt(recsz,enccy,opcyc)          = (enccy / opcyc) * 100.0

ylabfontsiz = fontsize*.8; 
labstr(str) = sprintf("{/=%.0f %.0f}",ylabfontsiz, str);


#-------------------------------------------------------------------------------
# arrays -- one entry per plot
#-------------------------------------------------------------------------------
# isenc?
arr_ids = " Receive Transmit ";
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
do for [k=1:2] {

    i=(k-1); j=0;
    set origin (xoff+i*xsiz),(yoff+j*ysiz)
    id = word(arr_ids, k);
    
    #min_other = word(arr_other,k);    # where the first ytic will appear
    #min_other2 = word(arr_other2,k);    # where the first ytic will appear
    #yhi0      = min_other * 2.6;      # top end of yrange
    yhi0      = 50 * 1000
    yhi      = 50 
    set yrange[0:yhi]

    #mytitle = toupper(id)
    mytitle = id
    set title mytitle offset 0,-.5
    #cutoff=500; # when to move from K-s to M-s
    #yticsuffix = (min_other < cutoff) ? "K" : "M";
    #norma(cyc) = (min_other < cutoff) ? cyc+0 : cyc/1000.0;
    norma(cyc) = cyc / 1000.0
    #yticfmt    = (min_other < cutoff) ? "%.0f" : "%.1f";

    #yic        = sprintf(yticfmt, norma(min_other));
    #yic2       = sprintf(yticfmt, norma(min_other2));
    #yhi        = sprintf(yticfmt, norma(yhi0));
    #
    #if( yhi > 0 ) {set yrange [0:yhi]} else {set yrange [0:*]}
    #if( yic > 0 ) {set ytics (yic.yticsuffix yic, yic2.yticsuffix  yic2, yic3.yticsuffix  yic3, yic4.yticsuffix  yic4)  } else {set ytics autofr}

    #set ytics format "%g".yticsuffix offset .25,0
    set ytics format "%gK" offset .25,0
    if (k==2) {
# This is Tx
	    plot sprintf("model.tx.csv") \
	       u   (norma(    other($2,$3,$4,$5    )))  ls 1   t 'other'            , \
	    '' u   (norma(      enc($2,$3,$4,$5    )))  ls 2   t 'crypto'         , \
	    '' u 0:(norma(  allplus($2,$3,$4,$5,yhi0))):(labstr(enc_prcnt($2,$3,$4)))                   \
						  ls 4 not            w labels
    } else {
# This is Rx
	    plot sprintf("model.rx.csv") \
	       u   (norma(    other($2,$7,$4,$5    )))  ls 1   t 'other'            , \
	    '' u   (norma(      enc($2,$7,$4,$5    )))  ls 2   t 'crypto'         , \
	    '' u 0:(norma(  allplus($2,$7,$4,$5,yhi0))):(labstr(enc_prcnt($2,$7,$4)))                   \
						  ls 4 not            w labels
    }

    #'' u 0:(norma(msurdmnus($8,yhi0))):(labstr(msuredpct2($16, $17, $6, $5)))     \
    #                                      ls 4   not          w labels
    
    set ytics autofreq
    set yrange [*:*]
    unset label 1
    unset label 2
    unset label 3
    unset key
}
