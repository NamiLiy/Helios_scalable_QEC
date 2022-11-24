#
# Various ways of displaying distribution of y values in a data file
# 1) Violin plots (bee swarm with large number of points)
# 2) Gaussian jitter
# 3) Random jitter
# 4) kernel density
#

set terminal pdf enhanced font "Times-Roman"
set output 'buffer_variation.pdf'



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
plot "../scripts/d7_buffer_size_effect_1.csv" using 1:(1) smooth kdensity bandwidth 1. with filledcurves above y lt 9 title 'B'
set table $kdensity2
plot "../scripts/d7_buffer_size_effect_1.csv" using 1:(1) smooth kdensity bandwidth 1. with filledcurves above y lt 10 title 'A'
set table $kdensity3
plot "../scripts/d7_buffer_size_effect_1.csv" using 1:(1) smooth kdensity bandwidth 1. with filledcurves above y lt 11 title 'C'
unset table
unset key

set xlabel "buffer size"
set ylabel "decoding time (cycles)"
set xrange [8 : 14]

unset xtics
set xtics ("1" 9, "2" 11, "4" 13)

set label at graph 0.166666666666667,0.209975 "" point  pointtype 2 pointsize 1
set label at graph 0.5,0.209975 "" point  pointtype 2 pointsize 1
set label at graph 0.833333333333333,0.209975 "" point  pointtype 2 pointsize 1

plot $kdensity1 using (9 + $2/300000.):1 with filledcurve x=9 lt 2, \
     '' using (9 - $2/300000.):1 with filledcurve x=9 lt 2, \
     $kdensity2 using (11 + $2/300000.):1 with filledcurve x=11 lt 2, \
     '' using (11 - $2/300000.):1 with filledcurve x=11 lt 2, \
     $kdensity3 using (13 + $2/300000.):1 with filledcurve x=13 lt 2, \
     '' using (13 - $2/300000.):1 with filledcurve x=13 lt 2