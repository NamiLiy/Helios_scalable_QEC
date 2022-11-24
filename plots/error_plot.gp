set terminal pdf enhanced font "Times-Roman"
set output 'distribution_plot_7.pdf'

set logscale y

set style fill solid
set boxwidth 0.5

set ylabel "frequency"
set xlabel "decoding time (cycles)"

#set datafile separator ","
plot 'd7_fpga.txt' using 1:2 with boxes notitle