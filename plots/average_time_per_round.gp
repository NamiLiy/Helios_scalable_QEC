set terminal pdf enhanced font "Times-Roman,16"
set output 'average_case_per_round.pdf'

set xlabel 'code distance (d)'   font ",16"                # x-axis label
set ylabel 'time per measurement round (ns)'  font ",16"   # y-axis label

set ytics nomirror
set xtics nomirror
set yrange [60:220]

set key font ",16"
set key spacing 1
set key at 14, 200
set xrange [1:17]
set xtics 1,2,17
set ytics 60,20,220
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


plot "average_time.txt" using 1:($11*10) with linespoints title " p = 0.0005" ls 1, "average_time.txt" using 1:($12*10) with linespoints title "p = 0.001" ls 2, "average_time.txt" using 1:($13*10) with linespoints title "p = 0.005" ls 3

# plot "average_time.txt" using 1:2:5:6 with yerrorbars title "p = 0.0005" lt 1, "average_time.txt" using 1:2 with lines notitle lt 1, "average_time.txt" using 1:3:7:8 with yerrorbars title "p = 0.001" lt 2, "average_time.txt" using 1:3 with lines notitle lt 2, "average_time.txt" using 1:4:9:10 with yerrorbars title "p = 0.005" lt 3,"average_time.txt" using 1:4 with linespoints notitle lt 3