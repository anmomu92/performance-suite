set terminal svg 
set output 'throughput.svg'
set title 'Connection throughput'

set xlabel "Input injection (Mbps)"
set ylabel "Throughput (Mbps)"
set boxwidth 0.5 
set style fill solid

set key top left
set offsets 0.5, 0.5, 0, 0
plot "throughput.txt" using 0:2:xtic(1) with boxes title "Throughput", "" using 0:2:2 with labels font ',8' offset char 0,0.5 notitle ""
