set terminal pdf enhanced font "Times-Roman"
set output 'buffer_size.pdf'

set xlabel 'runtime(cycles)'                       # x-axis label
set ylabel 'CDF'                   # y-axis label

set ytics nomirror
set yrange [0:1]

set key font ",8"
set key spacing 1
# set key at 380, 20

# unset xtics
# set xtics ("someTicLabel1" 90, "someTicLabel2" 100)

plot "../scripts/d7_buffer_size_effect.txt" using 11:($12/1000000) smooth cumulative with lines title "1 : av 83.9967", "../scripts/d7_buffer_size_effect.txt" using 9:($10/1000000) smooth cumulative with lines title "2 : av 83.9962",  "../scripts/d7_buffer_size_effect.txt" using 7:($8/1000000) smooth cumulative with lines title "4 : av 83.9940", "../scripts/d7_buffer_size_effect.txt" using 5:($6/1000000) smooth cumulative with lines title "8 : av 83.9940", "../scripts/d7_buffer_size_effect.txt" using 3:($4/1000000) smooth cumulative with lines title "16 : av 83.9940", "../scripts/d7_buffer_size_effect.txt" using 1:($2/1000000) smooth cumulative with lines title "32 : av 83.9940",