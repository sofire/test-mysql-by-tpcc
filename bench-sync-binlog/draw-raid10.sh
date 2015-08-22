#!/bin/sh


wlist="1 2 4 8 16 20"
#wlists=""
for bp in $wlist
do
    outfile=tpcc.w100-raid10-bp-${bp}g

    #每10秒输出一次结果，合并6次
    #./tpcc-output-analyze.sh  tpcc.w${bp}.out 6 > w${bp}.log

    ../tpcc-output-analyze.sh  ${outfile}.out > ${outfile}.log
    wfiles="$wfiles ${outfile}.log"
done

#计算每
#paste $wfiles |awk '{for (i = 1; i <= NF; i++){if (i%3==1){printf "%d ", $i/60}else{printf "%s ", $i} }; print ""}' > w.log
#paste $wfiles |awk '{for (i = 1; i <= NF; i++){if (i%3==1){printf "%d ", $i/10}else{printf "%s ", $i} }; print ""}' > w.log

paste $wfiles > merge.log

datafile=merge.log 
out=w100-raid10-pool.jpg

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
set mxtics 5
set mytics 5
#set timefmt "%H:%M"
#set format x "%H:%M"

set timestamp "%Y-%m-%d %H:%M Draw by Liu dehong" 

#set format y "%.2f"
#计算每秒的次数
plot datafile using 3:(\$1/$n) title "raid10 poolsize=1G" with lines, \
    datafile using 6:(\$4/$n) title "raid10 poolsize=2G" with lines, \
    datafile using 9:(\$7/$n) title "raid10 poolsize=4G" with lines, \
    datafile using 12:(\$10/$n) title "raid10 poolsize=8G" with lines, \
    datafile using 15:(\$13/$n) title "raid10 poolsize=16G" with lines, \
    datafile using 18:(\$16/$n) title "raid10 poolsize=20G" with lines

EOP
