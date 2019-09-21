#!/usr/bin/gnuplot -p
fontsize=18
smallfontsize=14
set terminal postscript eps color enhanced fontsize;
set output "nginx.tls.eps"

#-------------------------------------------------------------------------------
# dimensions
#-------------------------------------------------------------------------------
xsiz = .30;  # x size of each subfig
ysiz = .25;  # y size of each subfig
ysiz2= .20;  #
xoff = .04;  # push all subfigs to right by xoff to make room for joint ylabel
xoff2= .00;  # margin at the right
yoff = .10;  # push all subfigs upwards by yoff to make room for joint xlabel
xnum = 2;    # how many subfigs per row
ynum = 2;    # how many subfigs per column
xall = xoff + xnum*xsiz + xoff2;  # x size of the entire multiplot figure
yall = yoff + ysiz + ysiz2;       # y size of the entire multiplot figure
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
set rmargin 1
set tmargin 1.5
set bmargin .5

#-------------------------------------------------------------------------------
# functions
#-------------------------------------------------------------------------------
labstr(n,d)  = (d<=0.1 ? "" : ((n/d >= 2) \
  ? sprintf("{/=%.0f %.1fx}", smallfontsize, n/d) \
  : ((n/d >= 1.005 || n/d < .995) \
    ? sprintf("{/=%.0f %+.0f%%}", smallfontsize, 100*n/d-100) \
    : sprintf("{/=%.0f %.1f%%}" , smallfontsize, 100*n/d-100) ) ) )
maxy(x)      = 98
f(y)         = y;

#-------------------------------------------------------------------------------
# axes, tics, borders, titles
#-------------------------------------------------------------------------------
set xtics ("4" 0,"16" 1,"64" 2,"256" 3) out nomirror scale .7 offset 0,.2
set xrange [-.70:3.7]
set ytics 5000000 offset .6,0 scale .6
set ytics nomirror out
set ytics format "%.0s"; # %s = mantisa; see gnuplot> help format specifiers
set yrange [0:f(27.5)]
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
unset key

#-------------------------------------------------------------------------------
# plot tput
#-------------------------------------------------------------------------------
arr_ids  = "1 8";
arr_yhi  = "55 125";
arr_ytic = "10 20";

unset xtics;
set xtics ("" 0,"" 1,"" 2,"" 3) out nomirror scale .7 offset 0,.2

do for [k=1:2] {

  i=(k-1); j=1;
  set origin (xoff+i*xsiz),(yoff+j*ysiz2);
  
  id  = word(arr_ids,  k);
  yhi = word(arr_yhi,  k);
  yti = word(arr_ytic, k);
  mytitle = id==1 ? id." core" : id." cores";

  
  set yrange [0:f(yhi)];
  set ytics 0, f(yti), f(yhi)
  set title mytitle offset 0,-.5
  
  if(k>1)     { unset ylabel; }
  if(k==1)    { set ylabel "Gbps" offset .1,0; }
  if(k==xnum) { set label 2 "NIC's\n"."max"  left offset 0,.5 \
		    at first -.5, first maxy(0) font ",".smallfontsize \
		    textcolor 'red'; }
  
  f = sprintf("result.tlszc.s.%s.csv", id);
  plot \
    maxy(x) not ls 5 w line, \
    f u (f($6)) t "https", \
    f u (f($7)) t "https+off" , \
    f u (f($8)) t "https+off+zerocopy" , \
    f u (f($9)) t "http" , \
    f u 0:(f($9)):(labstr($8,$6)) not w labels offset 0,.6 rotate by 0 \
      textcolor 'grey40'

  unset label 1; unset label 2;
  unset key;
}


#-------------------------------------------------------------------------------
# plot cpu
#-------------------------------------------------------------------------------
set size xsiz, ysiz2
set tmargin .5
unset title
set ytics format "%g"
set xtics format "%g"
set xtics ("16" 0,"64" 1,"256" 2,"1024" 3) out nomirror scale .7 offset 0,.2
set key top left width -2 spacing .95 samplen 1 reverse Left

arr_yhi  = ".5 5.5";
arr_ytic = ".1 1";

idlereal(cpu,ncores) = (100*ncores - cpu) / 100;
idle(cpu,ncores) = (ret = idlereal(cpu,ncores) , (ret < .1) ? 0 : ret)

labstr2(cpubas,cpuoff,ncores) = ( \
  d = idle(cpubas,ncores), \
  n = idle(cpuoff,ncores), \
  labstr(n,d) )

do for [k=1:2] {

  i=(k-1); j=0;
  set origin (xoff+i*xsiz),(yoff+j*ysiz2);
  
  id  = word(arr_ids,  k);
  yhi = word(arr_yhi,  k);
  yti = word(arr_ytic, k);
  
  set yrange [0:yhi];
  set ytics 0, yti, yhi;
  #set yrange [*:*]
  #set ytics autof
  
  if(k>1)     { unset ylabel; }
  if(k==1)    { set ylabel "idle cores" offset 1,0; }
  
  f = sprintf("result.tlszc.s.%s.csv", id);
  plot \
    f u (idle($2,$11)) t "https", \
    f u (idle($3,$11)) t "https+off" , \
    f u (idle($4,$11)) t "https+off+zc" , \
    f u (idle($5,$11)) t "http" , \
    f u 0:(idle($4,$11)):(labstr2($2,$4,$11)) not w labels offset 0,.8 \
      rotate by 0 textcolor 'grey40'

  unset label 1; unset label 2;
  unset key;
}

unset title

