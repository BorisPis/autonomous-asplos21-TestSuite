#!/usr/bin/gnuplot -p
fontsize=18
smallfontsize=14
set terminal postscript eps color enhanced fontsize;
set output "nginx3b_tls.eps"

#-------------------------------------------------------------------------------
# dimensions
#-------------------------------------------------------------------------------
xsiz = .22+.0172;  # x size of each subfi=g
ysiz = .35;  # y size of each subfig
xoff = .00;  # push all subfigs to right by xoff to make room for joint ylabel
xoff2= .006; # margin at the right
yoff = .12;  # push all subfigs upwards by yoff to make room for joint xlabel
xnum = 3;    # how many subfigs per row
ynum = 1;    # how many subfigs per column
xall = xoff + xnum*xsiz + xoff2;  # x size of the entire multiplot figure
yall = yoff + ynum*ysiz;          # y size of the entire multiplot figure
print xall, yall

set size xall,yall;  # entire fig dimensions
set multiplot;	     # this is what makes this fig a multiplot
set size xsiz,ysiz;  # dimensions of each subfig

#-------------------------------------------------------------------------------
# styles 
#-------------------------------------------------------------------------------
set style data histogram
set style histogram cluster gap 1.5
set style fill solid 1.0 border lt -1; # noborder

w=4; # line width (a regular variable, used below); 1 = default
p=1.2; # point size (a regular variable, used below); 1 = default

set style line 1 lt  1 lw 1             lc rgb 'purple';  # bar base
set style line 2 lt  1 lw 1             lc rgb 'green';   # bar off
set style line 3 lt  7 lw w pt 4 ps p   lc 'medium-blue'; # line base
set style line 4 lt -1 lw w pt 2 ps p;                    # line off
set style line 5 lt  1 lw w pt 3 ps p lc 'red' dt (1,.5); # line max

#-------------------------------------------------------------------------------
# left/right/top/botom margins -- important to fixate them for multiplot-s,
# otherwise gnuplot optimizes them for each subfig individually, making them
# look different
#-------------------------------------------------------------------------------
set lmargin 3
set rmargin 1.1
set tmargin 2.6
set bmargin 0.5

#-------------------------------------------------------------------------------
# functions
#-------------------------------------------------------------------------------
labstr(n,d)  = (d<=0.1 ? "" : ((n/d >= 2) \
  ? sprintf("{/=%.0f %.1fx}", smallfontsize, n/d) \
  : ((n/d >= 1.005 || n/d < .995) \
    ? sprintf("{/=%.0f %.0f%%}", smallfontsize, 100*n/d-100) \
    : sprintf("{/=%.0f %.1f%%}", smallfontsize, 100*n/d-100) ) ) )

tobw(tps,sz) = (tps * sz / 1000.0) * 8;
maxbw        = 2673; # in MB?
maxy(x)      = tobw(maxbw, 10**6)
#f(y)         = y*1000*1000;


#toGbps (tps,msgBytes) = (tps*msgBytes*8)/(1000*1000*1000);
toGbps (bw,unused) = bw;
tocores(cpu,ncores)   = (totcpu=ncores*100.0, ncores*(cpu/totcpu));
maxDiskGbps(x)        = 8*2673.0/1000.0;
maxNICGbps(x)        = 98;
#print maxDiskGbps(0);

#-------------------------------------------------------------------------------
# axes, tics, borders, titles
#-------------------------------------------------------------------------------
set xtics ("4" 0,"16" 1,"64" 2,"256" 3) out nomirror \
    scale .7 offset 0,.2 rotate by -25; # font ",16"
set xrange [-.70:3.5]

# set ytics 5000000
# set ytics format "%.0s"; # %s = mantisa; see gnuplot> help format specifiers
set ytics offset .6,0 scale .6 nomirror out

set border back;   # place borders below data
#unset border

#-------------------------------------------------------------------------------
# labels
#-------------------------------------------------------------------------------
set label 1 "file size [KiB]" \
    at screen (xoff+xsiz*xnum/2), screen 0.02 center

#-------------------------------------------------------------------------------
# misc
#-------------------------------------------------------------------------------
set datafile separator ","
set grid y lc "gray";
#set key at first -.8, first 12.2 samplen .5 reverse left Left spacing .9 
#set key at screen 0, screen 0 \
#  samplen .5 reverse left Left bottom maxcols 4 maxrows 1 width .5
set key at screen 0, screen 0 \
  samplen .5 reverse left Left bottom maxcols 4 maxrows 1 width 23 \
  maxrows 2 maxcols 2


#-------------------------------------------------------------------------------
# arrays
#-------------------------------------------------------------------------------
letters = "a b c d e f g h i j";
array arTitle[xnum];
array arYhi[xnum];
array arYtic[xnum];
array arCores[xnum];
do for [i=1:xnum] { atTitle="??"; arYhi[i]=0; arYtic[i]=0; arCores[i]=0}

i=1  ; arTitle[i]="1 core:\nGbps"  
i=i+1; arTitle[i]="8 cores:\nGbps" 
i=i+1; arTitle[i]="8 cores:\nbusy cores";

i=1  ; arYhi[i]=  40; arYtic[i]=10;  arCores[i]=1; 
i=i+1; arYhi[i]= 125; arYtic[i]=20;  arCores[i]=8; 
i=i+1; arYhi[i]=  10; arYtic[i]=2;  arCores[i]=8; 

#-------------------------------------------------------------------------------
# plot
#-------------------------------------------------------------------------------
do for [k=1:3] {

  i=(k-1); j=0;
  set origin (xoff+i*xsiz),(yoff+j);
  
  yhi    = arYhi[k];
  yti    = arYtic[k];
  cores  = arCores[k];
  letter = word(letters, k);
  mytitle= "(" . letter . ") " . arTitle[k];
  
  set yrange [0:yhi];
  set ytics 0, yti, yhi
  set title mytitle offset 0,-.5  

  if(k==2) { 
      set label 2 "NIC's\n"."max"  left offset 0,.5 \
           at first -.5, first maxNICGbps(0) font ",".smallfontsize  textcolor 'red'; 
  }

  c0        = (k<=2) ?  6 : 2;	# which column in the csv
  c1        = (k<=2) ? 11 : 11;	# which column in the csv
  higher    = (k<=2) ? c0+3 : c0+0;
  yv(y,z)   = (k<=2) ? toGbps(y,z) : tocores(y,z);
  lb(y1,y2) = (k<=2) ? labstr(y2,y1) : labstr(y2,y1);
  fix(y,z)  = (k==2 && yv(y,z) > 15 && yv(y,z) < 20 ) ? yv(y,z)+1.5 : yv(y,z);
  f         = sprintf("result.tlszc.s.%d.csv", cores);

  plot \
    maxNICGbps(x) not ls 5 w line, \
    f u    (yv(column(c0+0)  ,column(c1))) t "https", \
    f u    (yv(column(c0+1)  ,column(c1))) t "offload" , \
    f u    (yv(column(c0+2)  ,column(c1))) t "offload+zc" , \
    f u    (yv(column(c0+3)  ,column(c1))) t "http" , \
    f u 0:(fix(column(higher),column(c1))):(lb(column(c0+0),column(c0+2))) \
        not w labels offset 0,.8 rotate by 0 textcolor 'grey40' rotate by -25

  unset label 1; unset label 2;
  unset key;
}

