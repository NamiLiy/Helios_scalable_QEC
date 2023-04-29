#
# Various ways of displaying distribution of y values in a data file
# 1) Violin plots (bee swarm with large number of points)
# 2) Gaussian jitter
# 3) Random jitter
# 4) kernel density
#

set terminal pdf enhanced font "Times-Roman,16"
set output 'weight_variation.pdf'



set jitter overlap first 2
set style data points
unset key


set xlabel "maximum weight" font ",16" 
set ylabel "decoding time (ns)" font ",16" 
set xrange [8 : 16]

unset xtics
set xtics ("2" 9, "4" 11, "8" 13, "16" 15)

set ytics 0,200,1500
set yrange [0 : 1500]

set linetype  9 lc 'web-green' ps 0.0002 pt 5

set arrow 9 from 9,110 to 9,900 heads size screen 0.005,90 lt 9
set arrow 11 from 11,110 to 11,1160 heads size screen 0.005,90 lt 9
set arrow 13 from 13,110 to 13,1500 heads size screen 0.005,90 lt 9
set arrow 15 from 15,110 to 15,1500 heads size screen 0.005,90 lt 9

set label "" at graph 0.125, 0.1294266667 point  pointtype 2 pointsize 1 front
set label "" at graph 0.375, 0.16568 point  pointtype 2 pointsize 1 front
set label "" at graph 0.625, 0.2121266667 point  pointtype 2 pointsize 1 front
set label "" at graph 0.875, 0.3275 point  pointtype 2 pointsize 1 front

set label "max=1870" at graph 0.55, 1.03 font ",12"  front
set label "max=3360" at graph 0.80, 1.03 font ",12"  front


plot "../scripts/d13_expanded_weight_2.csv" using (9):($1) lt 9, \
    "../scripts/d13_expanded_weight_4.csv" using (11):($1) lt 9, \
    "../scripts/d13_expanded_weight_8.csv" using (13):($1) lt 9, \
    "../scripts/d13_expanded_weight_16.csv" using (15):($1) lt 9
