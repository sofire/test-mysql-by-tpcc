#!/bin/sh

set -x 

#
# innodb_pool_size 1G 2G 4G 8G 16G 20G
# warehourse 100 金士顿SSD 120G -c 128 -r 600 -l 1800
# warehourse 100 Raid10 SATA 2T -c 128 -r 600 -l 1800
# 2015.08.19 @ Liu Dehong
#

set -u
#set -x
set -e


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
wlist="1 2 4 8 16 20"

wh=100



for bp in $wlist
do
    break

    outlog=tpcc.w100-raid10-bp-${bp}g.out

    #恢复数据
    if ps awux |grep -q mysqld |grep 3306; then
        mysqladmin  shutdown
    fi

    #rsync -raP /data/3306backup-100/data /data/mysql/3306/
    time \cp -fr /data2/3306backup-100/data /data/mysql/3306/

    #将脏数据刷新到磁盘
    sync_data

    #/usr/local/mysql/bin/mysqld --defaults-file=/etc/my.552.cnf --basedir=/usr/local/mysql --datadir=$DR  --innodb_data_home_dir=$log2 --innodb_log_group_home_dir=$log2 --innodb_thread_concurrency=0 --innodb_buffer_pool_size=${bp}GB  --innodb_buffer_pool_instances=16 &
    /usr/bin/mysqld_safe --defaults-file=/data/mysql/3306/my.cnf --innodb_buffer_pool_size=${bp}GB --innodb_flush_log_at_trx_commit=2 --innodb_fast_shutdown=2 &
    #/usr/bin/mysqld_safe --defaults-file=/data/mysql/3306/my.cnf

    sleep 6
    sh ../show_variables.sh > mysql_variables.raid10.${bp}.txt

    #./tpcc_start -h localhost -d tpcc$bp -u root -p "" -w $bp -c 16 -r 10 -l 100 -f  tpcc.w${bp}.log  > tpcc.w${bp}.out
    #time (../tpcc_start -h localhost -d tpcc$bp -u root -p "" -w $bp -c 16 -r 10 -l 100 > $outlog)

    #并发128 热身10分钟 跑30分钟
    #time (../tpcc_start -h localhost -d tpcc$wh -u root -p "" -w $wh -c 128 -r 600 -l 1800 >  $outlog)

    #./tpcc_start localhost tpcc root "" 200 16 10 2000 | tee -a tpcc.bp${bp}.second_run.out

    #waitm
    mysqladmin  shutdown

    #将脏数据刷新到磁盘
    sync_data
done


for bp in $wlist
do
    outlog=tpcc.w100-ssd-bp-${bp}g.out

    #恢复数据
    if ps awux |grep -q mysqld |grep 3306; then
        mysqladmin  shutdown
    fi

    #rsync -raP /data2/3306backup-100/data /data/mysql/3306/
    time \cp -fr /data2/3306backup-100/data /data2/mysql/3306/

    #将脏数据刷新到磁盘
    sync_data

    #/usr/local/mysql/bin/mysqld --defaults-file=/etc/my.552.cnf --basedir=/usr/local/mysql --datadir=$DR  --innodb_data_home_dir=$log2 --innodb_log_group_home_dir=$log2 --innodb_thread_concurrency=0 --innodb_buffer_pool_size=${bp}GB  --innodb_buffer_pool_instances=16 &
    /usr/bin/mysqld_safe --defaults-file=/data2/mysql/3306/my.cnf --innodb_buffer_pool_size=${bp}GB --innodb_flush_log_at_trx_commit=2 --innodb_fast_shutdown=2 &
    #/usr/bin/mysqld_safe --defaults-file=/data/mysql/3306/my.cnf

    sleep 6
    sh ../show_variables.sh > mysql_variables.ssd.${bp}.txt

    #./tpcc_start -h localhost -d tpcc$bp -u root -p "" -w $bp -c 16 -r 10 -l 100 -f  tpcc.w${bp}.log  > tpcc.w${bp}.out
    #time (../tpcc_start -h localhost -d tpcc$bp -u root -p "" -w $bp -c 16 -r 10 -l 100 > $outlog)

    #并发128 热身10分钟 跑30分钟
    #time (../tpcc_start -h localhost -d tpcc$wh -u root -p "" -w $wh -c 128 -r 600 -l 1800 >  $outlog)
    time (../tpcc_start -h localhost -d tpcc$wh -u root -p "" -w $wh -c 128 -r 600 -l 1800 >  $outlog)

    #./tpcc_start localhost tpcc root "" 200 16 10 2000 | tee -a tpcc.bp${bp}.second_run.out

    #waitm
    mysqladmin  shutdown

    #将脏数据刷新到磁盘
    sync_data
done


sh ./draw.sh


