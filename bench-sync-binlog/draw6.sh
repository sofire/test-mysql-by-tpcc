#!/bin/sh



paste ../bench-ssd-sync/merge.log merge.log > merge6.log

datafile=merge6.log 
out=flush_log_at_trx_commit_012_v2.jpg

### goto user homedir and remove previous file
rm -f '$out'

n=10
gnuplot << EOP

### set data source file
datafile = '$datafile'

### set graph type and size
#set terminal jpeg size 640,480
set terminal jpeg size 800,600 font "../simsun.ttc,12"

### set titles
set grid x y
set xlabel "Time (sec)"
set ylabel "Transactions/sec"

### set output filename
set output '$out'

### build graph
# plot datafile with lines
set title "Mysql-5.6.25-73.1 W100 内存16G 并发128 持续30分" 
#plot datafile title "5.6.25-73.1, buffer pool: 16G W1" with lines, datafile using 3:4 title "5.6.25-73.1, buffer pool: 16G W2" with lines axes x1y1

#set xdata time
#set timefmt "%H:%M"
#set format x "%H:%M"

set timestamp "%Y-%m-%d %H:%M Draw by Liu dehong" 

#set format y "%.2f"
#计算每秒的次数
plot datafile using 3:(\$1/$n) title "SSD trx_commit=0" with lines, \
    datafile using 6:(\$4/$n) title "SSD trx_commit=1" with lines, \
    datafile using 9:(\$7/$n) title "SSD trx_commit=2" with lines, \
    datafile using 12:(\$10/$n) title "Raid10 trx_commit=0" with lines, \
    datafile using 15:(\$13/$n) title "Raid10 trx_commit=1" with lines, \
    datafile using 18:(\$16/$n) title "Raid10 trx_commit=2" with lines

EOP
