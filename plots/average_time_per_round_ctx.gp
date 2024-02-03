set terminal pdf enhanced font "Times-Roman,16"
set output 'context_switching.pdf'

set xlabel 'Resource Usage (100K LUTs)'   font ",16"                # x-axis label
set ylabel 'time per measurement round (ns)'  font ",16"   # y-axis label

set ytics nomirror
set xtics nomirror
set yrange [0:700]

set key font ",16"
set key spacing 1
set key at 6.5, 650
set xrange [0:8]
set xtics 0,1,8
set ytics 0,100,700
# set key maxrows 1
set key center
set key samplen 4
# set key spacing 0.1
set key width -3

# unset xtics
# set xtics ("someTicLabel1" 90, "someTicLabel2" 100)

set style line 1 lt rgb "black" lw 1 pt 1
set style line 2 lt rgb "black" lw 1 pt 3


plot "ctx_latency_per_cycle.csv" using 1:($2) with linespoints title "p = 0.001" ls 1, "ctx_latency_per_cycle.csv" using 1:($3) with linespoints title " p = 0.005" ls 2