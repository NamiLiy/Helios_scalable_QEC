set terminal pdf enhanced font "Times-Roman"
set output 'boxplot.1.pdf'

set style fill solid 0.5 border -1
set style boxplot outliers pointtype 7
set style data boxplot
set boxwidth  0.5
set pointsize 0.5
set style boxplot fraction 0.999
set style boxplot nooutliers
set style fill empty
unset key

set datafile separator ","

set label at graph 0.0714285714285714,0.1265 "" point  pointtype 2 pointsize 1
set label at graph 0.214285714285714,0.1576 "" point  pointtype 2 pointsize 1
set label at graph 0.357142857142857,0.209725 "" point  pointtype 2 pointsize 1
set label at graph 0.5,0.2555 "" point  pointtype 2 pointsize 1
set label at graph 0.642857142857143,0.297 "" point  pointtype 2 pointsize 1
set label at graph 0.785714285714286,0.31585 "" point  pointtype 2 pointsize 1
set label at graph 0.928571428571429,0.326375 "" point  pointtype 2 pointsize 1			

# plot '../scripts/d3_expanded.csv'

plot '../scripts/d3_expanded.csv' using (3):1, '../scripts/d5_expanded.csv' using (5):1, '../scripts/d7_expanded.csv' using (7):1, '../scripts/d9_expanded.csv' using (9):1, '../scripts/d11_expanded.csv' using (11):1, '../scripts/d13_expanded.csv' using (13):1, '../scripts/d15_expanded.csv' using (15):1
