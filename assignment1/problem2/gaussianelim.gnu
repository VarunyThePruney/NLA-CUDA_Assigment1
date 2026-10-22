set datafile separator ","

set terminal pngcairo size 1000,700
set output "gaussianelim.png"

set title "GPU Runtime"
set xlabel "Threads"
set ylabel "Runtime (seconds)"

set xtics (8,16,32)
set grid
set yrange [0:0.40]

plot "results.csv" using (($2==1000 && $1==1) ? $5 : 1/0):(($2==1000 && $1==1) ? $11 : 1/0) \
     with linespoints title "1000x1000", \
     "results.csv" using (($2==2000 && $1==1) ? $5 : 1/0):(($2==2000 && $1==1) ? $11 : 1/0) \
     with linespoints title "2000x2000"