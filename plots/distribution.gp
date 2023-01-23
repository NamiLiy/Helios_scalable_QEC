set terminal pdf enhanced font "Times-Roman"
set output 'distribution_7.pdf'

set datafile separator ","

n=100 #number of intervals
max=400. #max value
min=0. #min value
width=(max-min)/n #interval width
#function used to map a value to the intervals
hist(x,width)=width*floor(x/width)+width/2.0
set boxwidth width*0.9
set style fill solid 0.5 # fill style
# set logscale y
set xrange [0:400]
# set yrange [0:1000]

# set style line 1 lt 2 lw 2 pt 3 ps 0.5

# set arrow from 83.89, graph 0 to 83.89, graph 1 nohead
# set arrow from 165, graph 0 to 165, graph 1 nohead
# set arrow from 213, graph 0 to 213, graph 1 nohead 
#count and plot
plot "../scripts/d7_expanded.csv" u (hist($1,width)):(1.0) smooth freq w boxes lc rgb"green" notitle
