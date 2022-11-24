#
# Various ways of displaying distribution of y values in a data file
# 1) Violin plots (bee swarm with large number of points)
# 2) Gaussian jitter
# 3) Random jitter
# 4) kernel density
#

set terminal pdf enhanced font "Times-Roman"
set output 'violin_plot.pdf'



set jitter overlap first 2
set style data points

set linetype  9 lc "#80bbaa44" ps 0.5 pt 5
set linetype 10 lc "#8033bbbb" ps 0.5 pt 5
set linetype 15 lc rgb 'grey' ps 0.5 pt 5

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
plot "sim_distribution.txt" using 1:(1) smooth kdensity bandwidth 1. with filledcurves above y lt 9 title 'B'
set table $kdensity2
plot "sim_distribution.txt" using 2:(1) smooth kdensity bandwidth 1. with filledcurves above y lt 10 title 'A'
set table $kdensity3
plot "sim_distribution.txt" using 3:(1) smooth kdensity bandwidth 1. with filledcurves above y lt 11 title 'C'
set table $kdensity4
plot "sim_distribution.txt" using 4:(1) smooth kdensity bandwidth 1. with filledcurves above y lt 12 title 'C'
set table $kdensity5
plot "sim_distribution.txt" using 5:(1) smooth kdensity bandwidth 1. with filledcurves above y lt 13 title 'C'
set table $kdensity6
plot "sim_distribution.txt" using 6:(1) smooth kdensity bandwidth 1. with filledcurves above y lt 14 title 'C'
set table $kdensity7
plot "sim_distribution.txt" using 7:(1) smooth kdensity bandwidth 1. with filledcurves above y lt 14 title 'C'
set table $kdensity8
plot "../scripts/d3_expanded.csv" using 1:(1) smooth kdensity bandwidth 1. with filledcurves above y lt 15 title 'C'
set table $kdensity9
plot "../scripts/d5_expanded.csv" using 1:(1) smooth kdensity bandwidth 1. with filledcurves above y lt 15 title 'C'
set table $kdensity10
plot "../scripts/d7_expanded.csv" using 1:(1) smooth kdensity bandwidth 1. with filledcurves above y lt 15 title 'C'
unset table
unset key

set xlabel "distance (d)"
set ylabel "decoding time (cycles)"
set xrange [1:17]
set xtics 1,2,17

set label at graph 0.125,0.143391428571429 "" point  pointtype 2 pointsize 1
set label at graph 0.25,0.179745714285714 "" point  pointtype 2 pointsize 1
set label at graph 0.375,0.241822857142857 "" point  pointtype 2 pointsize 1
set label at graph 0.5,0.298254285714286 "" point  pointtype 2 pointsize 1
set label at graph 0.625,0.337837142857143 "" point  pointtype 2 pointsize 1
set label at graph 0.75,0.356857142857143 "" point  pointtype 2 pointsize 1
set label at graph 0.875,0.375434285714286 "" point  pointtype 2 pointsize 1			

plot $kdensity1 using (3 + $2/300.):1 with filledcurve x=3 lt 2, \
     '' using (3 - $2/300.):1 with filledcurve x=3 lt 2, \
     $kdensity2 using (5 + $2/300.):1 with filledcurve x=5 lt 2, \
     '' using (5 - $2/300.):1 with filledcurve x=5 lt 2, \
     $kdensity3 using (7 + $2/300.):1 with filledcurve x=7 lt 2, \
     '' using (7 - $2/300.):1 with filledcurve x=7 lt 2, \
     $kdensity4 using (9 + $2/300.):1 with filledcurve x=9 lt 2, \
     '' using (9 - $2/300.):1 with filledcurve x=9 lt 2, \
     $kdensity5 using (11 + $2/300.):1 with filledcurve x=11 lt 2, \
     '' using (11 - $2/300.):1 with filledcurve x=11 lt 2, \
     $kdensity6 using (13 + $2/300.):1 with filledcurve x=13 lt 2, \
     '' using (13 - $2/300.):1 with filledcurve x=13 lt 2, \
     $kdensity7 using (15 + $2/300.):1 with filledcurve x=15 lt 2, \
     '' using (15 - $2/300.):1 with filledcurve x=15 lt 2, \
     $kdensity8 using (3 + $2/300000.):1 with filledcurve x=3 lt 15, \
     '' using (3 - $2/300000.):1 with filledcurve x=3 lt 15, \
     $kdensity9 using (5 + $2/300000.):1 with filledcurve x=5 lt 15, \
     '' using (5 - $2/300000.):1 with filledcurve x=5 lt 15, \
     $kdensity10 using (7 + $2/300000.):1 with filledcurve x=7 lt 15, \
     '' using (7 - $2/300000.):1 with filledcurve x=7 lt 15