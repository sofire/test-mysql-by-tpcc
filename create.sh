#!/bin/sh

# 初始化测试数据库

CREATELOG=create.log

#WLIST="10 50 100 200 500"
#WLIST="10 50 100"
WLIST="1 2"
#WLIST="100"
for w in $WLIST; do
    echo "./tpcc_load_parallel.sh $w tpcc$w " >> $CREATELOG
    echo "" >> $CREATELOG

    (time (./tpcc_load_parallel.sh $w tpcc$w 2>&1 |tee -a $CREATELOG))  2>> $CREATELOG

    echo "" >> $CREATELOG
done
