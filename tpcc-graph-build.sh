#!/bin/bash

if [ "$1" = "" -o "$2" = "" ]; then
    echo $0 " datafile imgfile"
    exit 1
fi

### goto user homedir and remove previous file
rm -f '$2'

n=10
gnuplot << EOP

### set data source file
datafile = '$1'

### set graph type and size
#set terminal jpeg size 640,480
set terminal jpeg size 800,600 font "./simsun.ttc,12"

### set titles
set grid x y
set xlabel "Time (sec)"
set ylabel "Transactions/sec"

### set output filename
set output '$2'

### build graph
# plot datafile with lines
set title "Mysql-5.6.25-73.1 SSD-128G 内存16G 并发128 持续30分" 
#plot datafile title "5.6.25-73.1, buffer pool: 16G W1" with lines, datafile using 3:4 title "5.6.25-73.1, buffer pool: 16G W2" with lines axes x1y1

#set xdata time
#set timefmt "%H:%M"
#set format x "%H:%M"

set timestamp "%Y-%m-%d %H:%M Draw by Liu dehong" 

#set format y "%.2f"
#计算每秒的次数
plot datafile using 3:(\$1/$n) title "W10 1G" with lines, \
    datafile using 6:(\$4/$n) title "W50 5G" with lines, \
    datafile using 9:(\$7/$n) title "W100 10G" with lines, \
    datafile using 12:(\$10/$n) title "W200 20G" with lines, \
    datafile using 15:(\$13/$n) title "W500 50G" with lines

set label "Draw by Liu Dehong" at 10,10
EOP
