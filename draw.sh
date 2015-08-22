#!/bin/sh


wlist="10 50 100 200 500"
for bp in $wlist
do
    #每10秒输出一次结果，合并6次
    #./tpcc-output-analyze.sh  tpcc.w${bp}.out 6 > w${bp}.log
    ./tpcc-output-analyze.sh  tpcc.w${bp}.out > w${bp}.log
    wfiles="$wfiles w${bp}.log"
done

#计算每
#paste $wfiles |awk '{for (i = 1; i <= NF; i++){if (i%3==1){printf "%d ", $i/60}else{printf "%s ", $i} }; print ""}' > w.log
#paste $wfiles |awk '{for (i = 1; i <= NF; i++){if (i%3==1){printf "%d ", $i/10}else{printf "%s ", $i} }; print ""}' > w.log

paste $wfiles > w.log
paste $wfiles > ww.log

./tpcc-graph-build.sh w.log w.jpg
