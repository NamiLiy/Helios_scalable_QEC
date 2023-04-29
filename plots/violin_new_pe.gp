#
# Various ways of displaying distribution of y values in a data file
# 1) Violin plots (bee swarm with large number of points)
# 2) Gaussian jitter
# 3) Random jitter
# 4) kernel density
#

set terminal pdf enhanced font "Times-Roman,16"
set output 'violin_plot_new.pdf'



set jitter overlap first 2
set style data points

set linetype  9 lc "#80bbaa44" ps 1 pt 5
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

# set lt 2 lc rgb 'green' lw 100 pt 6


set table $kdensity1
plot "sim_distribution_new.txt" using 1:(1) smooth kdensity bandwidth 1. with filledcurves above y lt 2 title 'B'
set table $kdensity2
plot "sim_distribution_new.txt" using 2:(1) smooth kdensity bandwidth 1. with filledcurves above y lt 10 title 'A'
set table $kdensity3
plot "sim_distribution_new.txt" using 3:(1) smooth kdensity bandwidth 1. with filledcurves above y lt 11 title 'C'
set table $kdensity4
plot "sim_distribution_new.txt" using 4:(1) smooth kdensity bandwidth 1. with filledcurves above y lt 12 title 'C'
set table $kdensity5
plot "sim_distribution_new.txt" using 5:(1) smooth kdensity bandwidth 1. with filledcurves above y lt 13 title 'C'
set table $kdensity6
plot "sim_distribution_new.txt" using 6:(1) smooth kdensity bandwidth 1. with filledcurves above y lt 14 title 'C'

unset table
unset key

set xlabel "distance (d)" font ",16" 
set ylabel "decoding time (ns)" font ",16" 
set xrange [1:15]
set xtics 1,2,15



# set arrow 3 from 3,47 to 3,165 heads size screen 0.005,90 lt 15
# set arrow 5 from 5,47 to 5,170 heads size screen 0.005,90 lt 15
# set arrow 7 from 7,47 to 7,181 heads size screen 0.005,90 lt 15
# set arrow 9 from 9,47 to 9,207 heads size screen 0.005,90 lt 15
# set arrow 11 from 11,47 to 11,313 heads size screen 0.005,90 lt 15
# set arrow 13 from 13,47 to 13,261 heads size screen 0.005,90 lt 15
# set arrow 15 from 15,105 to 15,281 heads size screen 0.005,90 lt 15

# set arrow 2 from 3,47 to 3,190 heads size screen 0.005,90 lt 2
# set arrow 4 from 5,47 to 5,351 heads size screen 0.005,90 lt 2
# set arrow 6 from 7,47 to 7,346 heads size screen 0.005,90 lt 2

set label at graph 0.1428571429,0.226 "" point  pointtype 2 pointsize 1
set label at graph 0.2857142857,0.245 "" point  pointtype 2 pointsize 1
set label at graph 0.4285714286,0.280 "" point  pointtype 2 pointsize 1
set label at graph 0.5714285714,0.322 "" point  pointtype 2 pointsize 1
set label at graph 0.7142857143,0.357 "" point  pointtype 2 pointsize 1
set label at graph 0.8571428571,0.390 "" point  pointtype 2 pointsize 1
# set arrow 1 from graph 3,47 to 0,165 nohead lt 2


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
     '' using (13 - $2/300.):1 with filledcurve x=13 lt 2