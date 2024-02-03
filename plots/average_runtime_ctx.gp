set terminal pdf enhanced font "Times-Roman,16"
set output 'average_case.pdf'

set xlabel 'code distance (d)' font ",16"                 # x-axis label
set ylabel 'decoding time (ns)'  font ",16"                  # y-axis label

set ytics nomirror
set xtics nomirror
set yrange [0:1000]

# set key font ",16"
# set key spacing 1
# set key at 7, 410
set xrange [2:15]
set xtics 3,2,15
set ytics 0,100,700
# set key maxrows 1
# set key center
set key samplen 4
# set key spacing 0.1
# set key width -3

# unset xtics
# set xtics ("someTicLabel1" 90, "someTicLabel2" 100)

set style line 1 lt rgb "black" lw 1 pt 1
set style line 2 lt rgb "red" lw 1 pt 2
set style line 3 lt rgb "black" lw 1 pt 3
set style line 4 lt rgb "red" lw 1 pt 3


plot "ctx_latency.csv" using 1:($2) with linespoints title "p = 0.001" ls 1, "ctx_latency.csv" using 1:($3) with linespoints title "p = 0.001 time shared" ls 2, "ctx_latency.csv" using 1:($4) with linespoints title " p = 0.005" ls 3, "ctx_latency.csv" using 1:($5) with linespoints title " p = 0.005 time shared" ls 4

