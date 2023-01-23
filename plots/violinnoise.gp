#
# Various ways of displaying distribution of y values in a data file
# 1) Violin plots (bee swarm with large number of points)
# 2) Gaussian jitter
# 3) Random jitter
# 4) kernel density
#

set terminal pdf enhanced font "Times-Roman,16"
set output 'noise_variation.pdf'



set jitter overlap first 2
set style data points

set linetype  9 lc "#80bbaa44" ps 0.5 pt 5
set linetype 10 lc "#8033bbbb" ps 0.5 pt 5

# print $viol1

# plot $viol1 lt 9, $viol2 lt 10
# set datafile separator ","
# plot "../scripts/d9_expanded.csv" lt 9,

# set auto x
# set xtics 0,1,15
# unset ytics
# set border 3
# set margins screen .15, screen .85, screen .15, screen .85
# set key

set table $kdensity1
plot "../scripts/d7_0005_expanded.csv" using 1:(1) smooth kdensity bandwidth 1. with filledcurves above y lt 9 title 'B'
set table $kdensity2
plot "../scripts/d7_001_expanded.csv" using 1:(1) smooth kdensity bandwidth 1. with filledcurves above y lt 10 title 'A'
set table $kdensity3
plot "../scripts/d7_005_expanded.csv" using 1:(1) smooth kdensity bandwidth 1. with filledcurves above y lt 11 title 'C'
unset table
unset key

set xlabel "physical error rate (p)" font ",16" 
set ylabel "decoding time" font ",16" 
set xrange [8 : 14]

# set label at graph 0.2,0.1265 "" point  pointtype 2 pointsize 1				
# set label at graph 0.333333333333333,0.1576 "" point  pointtype 2 pointsize 1				
# set label at graph 0.466666666666667,0.209725 "" point  pointtype 2 pointsize 1				
# set label at graph 0.6,0.2555 "" point  pointtype 2 pointsize 1				
# set label at graph 0.733333333333333,0.297 "" point  pointtype 2 pointsize 1				
# set label at graph 0.866666666666667,0.31585 "" point  pointtype 2 pointsize 1

unset xtics
set xtics ("0.0005" 9, "0.001" 11, "0.005" 13)

set ytics 0,100,700
set yrange [0 : 700]

set arrow 9 from 9,47 to 9,373 heads size screen 0.005,90 lt 2
set arrow 11 from 11,47 to 11,466 heads size screen 0.005,90 lt 2
set arrow 13 from 13,47 to 13,613 heads size screen 0.005,90 lt 2

set label at graph 0.166666666666667,0.0976428571428571 "" point  pointtype 2 pointsize 1
set label at graph 0.5,0.119942857142857 "" point  pointtype 2 pointsize 1
set label at graph 0.833333333333333,0.191857142857143 "" point  pointtype 2 pointsize 1

# plot $kdensity1 using (9 + $2/30000000.):1 with filledcurve x=9 lt 2

plot $kdensity1 using (9 + $2/30000000.):1 with filledcurve x=9 lt 2, \
     '' using (9 - $2/30000000.):1 with filledcurve x=9 lt 2, \
     $kdensity2 using (11 + $2/30000000.):1 with filledcurve x=11 lt 2, \
     '' using (11 - $2/30000000.):1 with filledcurve x=11 lt 2, \
     $kdensity3 using (13 + $2/30000000.):1 with filledcurve x=13 lt 2, \
     '' using (13 - $2/30000000.):1 with filledcurve x=13 lt 2