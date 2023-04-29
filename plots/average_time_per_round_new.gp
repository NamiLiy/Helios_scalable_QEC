set terminal pdf enhanced font "Times-Roman,16"
set output 'average_case_per_round.pdf'

set xlabel 'code distance (d)'   font ",16"                # x-axis label
set ylabel 'time per measurement round (ns)'  font ",16"   # y-axis label

set ytics nomirror
set xtics nomirror
set yrange [5:45]

set key font ",16"
set key spacing 1
set key at 18, 40
set xrange [2:22]
set xtics 3,2,21
set ytics 5,5,45
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


plot "new_pe_latency.txt.csv" using 1:($7) with linespoints title " p = 0.0005" ls 1, "new_pe_latency.txt.csv" using 1:($3) with linespoints title "p = 0.001" ls 2, "new_pe_latency.txt.csv" using 1:($5) with linespoints title "p = 0.005" ls 3