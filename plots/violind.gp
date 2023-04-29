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
unset key


set xlabel "distance (d)" font ",16" 
set ylabel "decoding time (ns)" font ",16" 
set xrange [2 : 12]

unset xtics
set xtics ("5" 3, "9" 5, "13" 7, "17" 9, "21" 11)

set ytics 0,200,1500
set yrange [0 : 1500]

set linetype  9 lc 'web-green' ps 0.0002 pt 5

# set arrow 3 from 3,110 to 3,340 heads size screen 0.005,90 lt 9
# set arrow 5 from 5,110 to 5,430 heads size screen 0.005,90 lt 9
# set arrow 7 from 7,110 to 7,780 heads size screen 0.005,90 lt 9
# set arrow 9 from 9,110 to 9,750 heads size screen 0.005,90 lt 9
# set arrow 11 from 11,110 to 11,960 heads size screen 0.005,90 lt 9
# set arrow 13 from 13,110 to 13,900 heads size screen 0.005,90 lt 9

set arrow 3 from 3,110 to 3,430 heads size screen 0.005,90 lt 9
set arrow 5 from 5,110 to 5,750 heads size screen 0.005,90 lt 9
set arrow 7 from 7,110 to 7,900 heads size screen 0.005,90 lt 9
set arrow 9 from 9,110 to 9,1440 heads size screen 0.005,90 lt 9
set arrow 11 from 11,110 to 11,1500 heads size screen 0.005,90 lt 9

set label "max=1650" at graph 0.80, 1.03 font ",12"  front

# set label "" at graph 0.0833, 0.0753 point  pointtype 2 pointsize 1 front
# set label "" at graph 0.25, 0.08175333333 point  pointtype 2 pointsize 1 front
# set label "" at graph 0.4166666667, 0.09300666667 point  pointtype 2 pointsize 1 front
# set label "" at graph 0.5833333333, 0.10724 point  pointtype 2 pointsize 1 front
# set label "" at graph 0.75, 0.119 point  pointtype 2 pointsize 1 front
# set label "" at graph 0.9166666667, 0.1294266667 point  pointtype 2 pointsize 1 front

set label "" at graph 0.1, 0.08175333333 point  pointtype 2 pointsize 1 front
set label "" at graph 0.3, 0.10724 point  pointtype 2 pointsize 1 front
set label "" at graph 0.5, 0.1294266667 point  pointtype 2 pointsize 1 front
set label "" at graph 0.7, 0.1453466667 point  pointtype 2 pointsize 1 front
set label "" at graph 0.9, 0.1608933333 point  pointtype 2 pointsize 1 front




# plot "../scripts/d_expanded_3.csv" using (3):($1) lt 9, \
    "../scripts/d_expanded_5.csv" using (5):($1) lt 9, \
    "../scripts/d_expanded_7.csv" using (7):($1) lt 9, \
    "../scripts/d_expanded_9.csv" using (9):($1) lt 9, \
    "../scripts/d_expanded_11.csv" using (11):($1) lt 9, \
    "../scripts/d_expanded_13.csv" using (13):($1) lt 9

plot "../scripts/d_expanded_5.csv" using (3):($1) lt 9, \
    "../scripts/d_expanded_9.csv" using (5):($1) lt 9, \
    "../scripts/d_expanded_13.csv" using (7):($1) lt 9, \
    "../scripts/d_expanded_17.csv" using (9):($1) lt 9, \
    "../scripts/d_expanded_21.csv" using (11):($1) lt 9
