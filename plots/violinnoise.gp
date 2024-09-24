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

# set table $kdensity1
# plot "../scripts/d13_0005_expanded.csv" using 1:(1) smooth kdensity bandwidth 1. with filledcurves above y lt 2 title 'B'
# set table $kdensity2
# plot "../scripts/d13_001_expanded.csv" using 1:(1) smooth kdensity bandwidth 1. with filledcurves above y lt 2 title 'A'
# set table $kdensity3
# plot "../scripts/d13_005_expanded.csv" using 1:(1) smooth kdensity bandwidth 1. with filledcurves above y lt 2 title 'C'
# unset table
unset key

set xlabel "physical error rate (p)" font ",16" 
set ylabel "decoding time (ns)" font ",16" 
set xrange [8 : 18]

unset xtics
set xtics ("0.0005" 9, "0.001" 11, "0.005" 13, "0.01" 15, "0.02" 17)

set ytics 0,200,1500
set yrange [0 : 1500]

set linetype  9 lc 'web-green' ps 0.0002 pt 5

set arrow 9 from 9,110 to 9,720 heads size screen 0.005,90 lt 9
set arrow 11 from 11,110 to 11,900 heads size screen 0.005,90 lt 9
set arrow 13 from 13,110 to 13,1430 heads size screen 0.005,90 lt 9
set arrow 15 from 15,160 to 15,1500 heads size screen 0.005,90 lt 9
set arrow 17 from 17,330 to 17,1500 heads size screen 0.005,90 lt 9

set label "" at graph 0.1, 0.1134266667 point  pointtype 2 pointsize 1 front
set label "" at graph 0.3, 0.1294266667 point  pointtype 2 pointsize 1 front
set label "" at graph 0.5, 0.2172066667 point  pointtype 2 pointsize 1 front
set label "" at graph 0.7, 0.308 point  pointtype 2 pointsize 1 front
set label "" at graph 0.9, 0.5419 point  pointtype 2 pointsize 1 front

set label "max=1790" at graph 0.58, 1.03 font ",12"  front
set label "max=2940" at graph 0.82, 1.03 font ",12"  front


plot "../scripts/d13_expanded_001.csv" using (11):($1) lt 9,   \
 "../scripts/d13_expanded_005.csv" using (13):($1) lt 9, \
 "../scripts/d13_expanded_0005.csv" using (9):($1) lt 9, \
 "../scripts/d13_expanded_01.csv" using (15):($1) lt 9, \
 "../scripts/d13_expanded_02.csv" using (17):($1) lt 9



# plot $kdensity1 using (9 + $2/30000000.):1 with filledcurve x=9 lt 2

# plot $kdensity1 using (9 + $2/100000.):1 with filledcurve x=9 lt 2, \
#      '' using (9 - $2/100000.):1 with filledcurve x=9 lt 2, \
#      $kdensity2 using (11 + $2/100000.):1 with filledcurve x=11 lt 2, \
#     '' using (11 - $2/100000.):1 with filledcurve x=11 lt 2, \
#      $kdensity3 using (13 + $2/100000.):1 with filledcurve x=13 lt 2, \
#      '' using (13 - $2/100000.):1 with filledcurve x=13 lt 2