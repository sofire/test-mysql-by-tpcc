#!/bin/sh

set -x 

#
# sync_bin 0 VS 1
# innodb_pool_size 16G 
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


function run(){

    #wlist="10 50 100 200 500"
    #wlist="100"
    #wlist="0 1"
    wlist="1"

    wh=100

    hd=$1

    if [ $hd == 'ssd' -o $hd == "SSD" ];then
        mysql_hd=/data2
    else
        mysql_hd=/data
    fi

    for sb in $wlist
    do

        outlog=tpcc.w100-${hd}-syncbinlog-${sb}.out

        #恢复数据
        if ps awux |grep -q mysqld |grep 3306; then
            mysqladmin  shutdown
        fi

        #rsync -raP /data/3306backup-100/data /data/mysql/3306/
        time \cp -fr /data2/3306backup-100/data ${mysql_hd}/mysql/3306/
        #只保留最后N个binlog，防止磁盘空间不足
        for _binlog in `ls ${mysql_hd}/mysql/3306/binlog/binlog.0* |head -n -5 `; do
            ls $_binlog
            #\rm $_binlog
        done

        #将脏数据刷新到磁盘
        sync_data

        #/usr/local/mysql/bin/mysqld --defaults-file=/etc/my.552.cnf --basedir=/usr/local/mysql --datadir=$DR  --innodb_data_home_dir=$log2 --innodb_log_group_home_dir=$log2 --innodb_thread_concurrency=0 --innodb_buffer_pool_size=${bp}GB  --innodb_buffer_pool_instances=16 &
        /usr/bin/mysqld_safe --defaults-file=${mysql_hd}/mysql/3306/my.cnf --log_bin=${mysql_hd}/mysql/3306/binlog/binlog --sync_binlog=${sb} --innodb_flush_log_at_trx_commit=2 --innodb_fast_shutdown=2 &
        #/usr/bin/mysqld_safe --defaults-file=/data/mysql/3306/my.cnf

        sleep 6
        sh ../show_variables.sh > mysql_variables.${hd}.${sb}.txt

        #./tpcc_start -h localhost -d tpcc$bp -u root -p "" -w $bp -c 16 -r 10 -l 100 -f  tpcc.w${bp}.log  > tpcc.w${bp}.out
        #time (../tpcc_start -h localhost -d tpcc$bp -u root -p "" -w $bp -c 16 -r 10 -l 100 > $outlog)

        #并发128 热身10分钟 跑30分钟
        time (../tpcc_start -h localhost -d tpcc$wh -u root -p "" -w $wh -c 128 -r 600 -l 7200 >  $outlog)

        #./tpcc_start localhost tpcc root "" 200 16 10 2000 | tee -a tpcc.bp${bp}.second_run.out

        #waitm
        mysqladmin  shutdown

        #将脏数据刷新到磁盘
        sync_data
    done
}

#run raid10

run ssd


sh ./draw.sh


