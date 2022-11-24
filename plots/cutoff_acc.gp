set terminal pdf enhanced font "Times-Roman"
set output 'cutoff_acc.pdf'

set xlabel 'cutoff time (cycles)'                       # x-axis label
set ylabel 'average runtime (cycles)'                   # y-axis label

set ytics nomirror
set y2tics nomirror
set format y2 "%g%%"
set y2tics 0, 20, 100
set y2range [0:100]
set y2label 'logical error %'

set key font ",8"
set key spacing 1
set key at 380, 20


plot "../scripts/d7_cutoff_accuracy.txt" using 1:4 with lines title "average time",  "../scripts/d7_cutoff_accuracy.txt" using 1:5 with lines axis x1y2 title "logical error %"