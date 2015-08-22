#!/bin/sh
set -u
set -x
set -e

DR="/mnt/fio320"
BD="/mnt/fio/back"

WT=10
RT=3600

ROWS=80000000

#log2="/bench/"
log2="$DR/"

# restore from backup

rm -fr $DR/*

echo $log2
for nm in ibdata1 ib_logfile0 ib_logfile1
do
	rm -f $log2/$nm
	cp $BD/$nm $log2
done


cp -r $BD/* $DR

chown mysql.mysql -R $DR
chown mysql.mysql -R $log2


function waitm {

while [ true ]
do

	mysql -e "set global innodb_max_dirty_pages_pct=0" mysql

	wt=`mysql -e "SHOW ENGINE INNODB STATUS\G" | grep "Modified db pages" | sort -u | awk '{print $4}'`
	if [[ "$wt" -lt 100 ]] ;
	then
		mysql -e "set global innodb_max_dirty_pages_pct=90" mysql
		break 
	fi

	echo "mysql pages $wt"
	sleep 10
done

}

for bp in 20 18 16 14 12 10 8 6
do

	/usr/local/mysql/bin/mysqld --defaults-file=/etc/my.552.cnf --basedir=/usr/local/mysql --datadir=$DR  --innodb_data_home_dir=$log2 --innodb_log_group_home_dir=$log2 --innodb_thread_concurrency=0 --innodb_buffer_pool_size=${bp}GB  --innodb_buffer_pool_instances=16 &

	sleep 60

	./tpcc_start localhost tpcc root "" 200 16 10 2000 | tee -a tpcc.bp${bp}.second_run.out


	waitm


	mysqladmin  shutdown

done
