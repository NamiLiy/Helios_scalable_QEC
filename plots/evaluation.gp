set terminal pdf enhanced font "Times-Roman"
set output 'runqueue_evaluvation.pdf'

set size ratio 1.09 # golden ratio

set multiplot layout 1, 2 ;

#set lmargin 13
#set bmargin 5

# set size square
set boxwidth 1 absolute
set style data histogram
set style histogram cluster gap 1


#set style fill solid border rgb "black"
set style fill pattern 1 border rgb "black"
set auto x
set yrange [0:100]

set xlabel "cores:" font "Times-Roman, 12" offset -9.6,1.5
set ylabel "Cycles" font "Times-Roman, 14" offset -0.0


set xtics nomirror font "Times-Roman, 12"
set ytics nomirror font "Times-Roman, 14" 

# set logscale y

set key font "Times-Roman, 14" spacing 1.3 samplen 3 
set key tmargin
set key Left reverse above vertical maxrows 1
set key at 10,113
#set size 0.45,0.9
set origin 0, 0.025

set label "(a) Remove only" font "Times Bold, 16" at 0.5,-18
set label "(b) Empty task" font "Times Bold, 16" at 12.5,-18


set datafile separator ","

plot 'runqueue_evaluvation_single.csv' using 3:xtic(1) title "with state spill" fill solid 0.75 lc rgb "grey", \
        '' using 2:xtic(1) title "state spill free", \


