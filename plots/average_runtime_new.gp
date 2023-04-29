set terminal pdf enhanced font "Times-Roman,16"
set output 'average_case.pdf'

set xlabel 'code distance (d)' font ",16"                 # x-axis label
set ylabel 'decoding time (ns)'  font ",16"                  # y-axis label

set ytics nomirror
set xtics nomirror
set yrange [100:450]

set key font ",16"
set key spacing 1
set key at 7, 410
set xrange [2:22]
set xtics 3,2,21
set ytics 100,50,450
# set key maxrows 1
set key center
set key samplen 4
# set key spacing 0.1
set key width -3

# unset xtics
# set xtics ("someTicLabel1" 90, "someTicLabel2" 100)

set style line 1 lt rgb "black" lw 1 pt 1
set style line 2 lt rgb "black" lw 1 pt 2
set style line 3 lt rgb "black" lw 1 pt 3


plot "new_pe_latency.txt.csv" using 1:($6) with linespoints title "p = 0.0005" ls 1, "new_pe_latency.txt.csv" using 1:($2) with linespoints title " p = 0.001" ls 2, "new_pe_latency.txt.csv" using 1:($4) with linespoints title " p = 0.005" ls 3

