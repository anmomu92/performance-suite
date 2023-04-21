set terminal svg 
set output 'loss.svg'
set title 'UDP connection datagram loss'

set xlabel "Input injection (Mbps)"
set ylabel "Datagram loss (%)"
set style line 1 \
  linecolor rgb '#ad6000' \
  linetype 1 linewidth 2 \
  pointtype 7 pointsize 0.5

set key top left
set offsets 0.5, 0.5, graph 0.1, 0
plot "loss.txt" using 0:2:xtic(1) with linespoints linestyle 1 title "Datagram loss", "" using 0:2:2 with labels font ',8' offset char 0,0.5 notitle ""
