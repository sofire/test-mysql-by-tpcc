#!/bin/sh

set -x 

#
# innodb_flush_log_at_tr_commit  0 1 2
# warehourse 100 金士顿SSD 120G -c 128 -r 600 -l 1800
# 2015.08.19 @ Liu Dehong
#

set -u
#set -x
set -e

DR="/data/mysql/3306/data"
BD="/data/tpcc/data"

WT=10
RT=3600


# restore from backup

#rm -fr $DR/*

#cp -r $BD/* $DR

chown mysql.mysql -R $DR


function waitm {

	while [ true ]
	do

		mysql -e "set global innodb_max_dirty_pages_pct=0" mysql

		wt=`mysql -e "SHOW ENGINE INNODB STATUS\G" | grep "Modified db pages" | sort -u | head -n 1 | awk '{print $4}'`
		if [[ "$wt" -lt 100 ]] ;
		then
            mysql -e "set global innodb_max_dirty_pages_pct=90" mysql
            break 
		fi

		echo "mysql pages $wt"
		sleep 10
	done

}

function sync_data(){

    #将脏数据刷新到磁盘
    sync

    #清除OS Cache
    echo 3 > /proc/sys/vm/drop_caches  
    swapoff -a && swapon -a
}

#wlist="10 50 100 200 500"
#wlist="100"
wlist="2"

bp=100
for trx in $wlist
do
    outlog=tpcc.w100-trx-${trx}.out

    #恢复数据
    if ps awux |grep -q mysqld |grep 3306; then
        mysqladmin  shutdown
    fi

    #rsync -raP /data/3306backup-100/data /data/mysql/3306/
    \cp -fr /data/3306backup-100/data /data/mysql/3306/

    #将脏数据刷新到磁盘
    sync_data

    #/usr/local/mysql/bin/mysqld --defaults-file=/etc/my.552.cnf --basedir=/usr/local/mysql --datadir=$DR  --innodb_data_home_dir=$log2 --innodb_log_group_home_dir=$log2 --innodb_thread_concurrency=0 --innodb_buffer_pool_size=${bp}GB  --innodb_buffer_pool_instances=16 &
    /usr/bin/mysqld_safe --defaults-file=/data/mysql/3306/my.cnf --innodb_flush_log_at_trx_commit=$trx --innodb_fast_shutdown=2 &
    #/usr/bin/mysqld_safe --defaults-file=/data/mysql/3306/my.cnf

    sleep 6
    sh ../show_variables.sh > mysql_variables.${trx}.txt

    #./tpcc_start -h localhost -d tpcc$bp -u root -p "" -w $bp -c 16 -r 10 -l 100 -f  tpcc.w${bp}.log  > tpcc.w${bp}.out
    #../tpcc_start -h localhost -d tpcc$bp -u root -p "" -w $bp -c 16 -r 10 -l 100 > tpcc.w100-trx-${trx}.out

    #并发128 热身10分钟 跑30分钟
    ../tpcc_start -h localhost -d tpcc$bp -u root -p "" -w $bp -c 128 -r 600 -l 1800 >  $outlog

    #./tpcc_start localhost tpcc root "" 200 16 10 2000 | tee -a tpcc.bp${bp}.second_run.out

    #waitm
    mysqladmin  shutdown

    #将脏数据刷新到磁盘
    sync_data
done


sh ./draw.sh


