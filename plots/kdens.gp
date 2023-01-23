#!/usr/local/bin/gnuplot -persist
set terminal pngcairo  transparent enhanced font "arial,10" fontscale 1.0 size 600, 400 
set output 'violinplot.4.png'
set border 2 front lt black linewidth 1.000 dashtype solid
unset key
set style data filledcurves below 
unset xtics
set ytics border in scale 1,0.5 nomirror norotate  autojustify
set ytics  rangelimit autofreq 
set title "kdensity mirrored sideways to give a violin plot" 
set title  font ",15" textcolor lt -1 norotate
set xrange [ -1.00000 : 5.00000 ] noreverse writeback
set x2range [ * : * ] noreverse writeback
set yrange [ * : * ] noreverse writeback
set y2range [ * : * ] noreverse writeback
set zrange [ * : * ] noreverse writeback
set cbrange [ * : * ] noreverse writeback
set rrange [ * : * ] noreverse writeback
set colorbox vertical origin screen 0.9, 0.2 size screen 0.05, 0.6 front  noinvert bdefault
NO_ANIMATION = 1
nsamp = 3000
y = 179.81901992101
J = 0.1
## Last datafile plotted: "$kdensity1"
plot "../scripts/d13_expanded.csv" using (1 + $2/20.):1 with filledcurve x=1 lt 10,      '' using (1 - $2/20.):1 with filledcurve x=1 lt 10,  