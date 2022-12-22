set terminal pdf enhanced font "Times-Roman,18"
set output 'average_case.pdf'

set xlabel 'code distance (d)' font ",18"                 # x-axis label
set ylabel 'decoding time'  font ",18"                  # y-axis label

set ytics nomirror
# set yrange [0:1]

set key font ",18"
set key spacing 1
set key at 9, 210
set xrange [1:17]
set xtics 1,2,17

# unset xtics
# set xtics ("someTicLabel1" 90, "someTicLabel2" 100)


plot "average_time.txt" using 1:2 with linespoints title " p = 0.0005" lt 1, "average_time.txt" using 1:3 with linespoints title "p = 0.001" lt 2, "average_time.txt" using 1:4 with linespoints title "p = 0.005" lt 3

# plot "average_time.txt" using 1:2:5:6 with yerrorbars title "p = 0.0005" lt 1, "average_time.txt" using 1:2 with lines notitle lt 1, "average_time.txt" using 1:3:7:8 with yerrorbars title "p = 0.001" lt 2, "average_time.txt" using 1:3 with lines notitle lt 2, "average_time.txt" using 1:4:9:10 with yerrorbars title "p = 0.005" lt 3,"average_time.txt" using 1:4 with linespoints notitle lt 3