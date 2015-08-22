#!/bin/sh

datafile=merge.log 
out=raid10-ssd-sync-binlog.jpg

wlist="0 1"
for i in $wlist
do
    outfile=tpcc.w100-raid10-syncbinlog-${i}
    outfile2=tpcc.w100-ssd-syncbinlog-${i}

    #每10秒输出一次结果，合并6次
    #./tpcc-output-analyze.sh  tpcc.w${bp}.out 6 > w${bp}.log

    ../tpcc-output-analyze.sh  ${outfile}.out > ${outfile}.log
    ../tpcc-output-analyze.sh  ${outfile2}.out > ${outfile2}.log

    wfiles="$wfiles ${outfile}.log"
    wfiles2="$wfiles2 ${outfile2}.log"
done

#计算每
#paste $wfiles |awk '{for (i = 1; i <= NF; i++){if (i%3==1){printf "%d ", $i/60}else{printf "%s ", $i} }; print ""}' > w.log
#paste $wfiles |awk '{for (i = 1; i <= NF; i++){if (i%3==1){printf "%d ", $i/10}else{printf "%s ", $i} }; print ""}' > w.log

paste $wfiles $wfiles2 > $datafile


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
# first draw the minor tics
#set mxtics 10 
set mytics 5
# set grid mxtics mytics ls 
set grid x y mx my
set xlabel "Time (sec)"
set ylabel "Transactions/sec"

### set output filename
set output '$out'

### build graph
# plot datafile with lines
set title "Mysql-5.6.25-73.1 W100 内存16G 并发128 持续120分" 
#plot datafile title "5.6.25-73.1, buffer pool: 16G W1" with lines, datafile using 3:4 title "5.6.25-73.1, buffer pool: 16G W2" with lines axes x1y1

#set xdata time
#set timefmt "%H:%M"
#set format x "%H:%M"

set timestamp "%Y-%m-%d %H:%M Draw by Liu dehong" 
set key height 2

#set format y "%.2f"
#计算每秒的次数
plot datafile using 3:(\$1/$n) title "raid10 sync_binlog=0" with lines, \
    datafile using 6:(\$4/$n) title "raid10 sync_binlog=1" with lines, \
    datafile using 9:(\$7/$n) title "ssd sync_binlog=0" with lines lw 0, \
    datafile using 12:(\$10/$n) title "ssd sync_binlog=1" with lines lw 0

EOP
