set terminal svg 
set output 'jitter.svg'
set title 'UDP connection jitter'

set xlabel "Input injection (Mbps)"
set ylabel "Jitter (Mbps)"
set style line 1 \
    linecolor rgb '#0060ad' \
    linetype 1 linewidth 2 \
    pointtype 7 pointsize 0.5

set key top left
set offsets 0.5, 0.5, graph 0.1, graph 0.1 
plot "jitter.txt" using 0:2:xtic(1) with linespoints linestyle 1 title "Jitter", "" using 0:2:2 with labels font ',8' offset char 0,0.5 notitle ""
