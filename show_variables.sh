#!/bin/sh
# 显示Mysql的重要参数
# Edit by Liu dehong@2015.08.18


TMP=/tmp/mysql_varibles
mysql -S /tmp/mysql3306.sock -uroot -proot  -N -e "show variables"  > $TMP 2>/dev/null

echo 

cat > /tmp/mysql_vlist << "EOF" &&
version
innodb_version

innodb_buffer_pool_size = 64G
innodb_log_buffer_size = 64M
innodb_max_dirty_pages_pct = 50

innodb_data_file_path = ibdata1:1G:autoextend
innodb_log_file_size = 4G
innodb_log_files_in_group = 2
innodb_file_per_table = 1
innodb_status_output = 1

innodb_autoinc_lock_mode = 1
innodb_thread_concurrency = 0
innodb_read_io_threads = 8
innodb_write_io_threads = 8

innodb_flush_method = O_DIRECT
innodb_io_capacity = 10000
innodb_io_capacity_max = 20000

transaction-isolation = READ-COMMITTED
tx_isolation = READ-COMMITTED
innodb_flush_log_at_trx_commit = 1
innodb_rollback_on_timeout = 1

sync_binlog = 1

EOF

for i in `awk '{print $1}' /tmp/mysql_vlist `; do
	#echo $i
	#grep "$i" $TMP |awk '{if($1=="'$i'"){print $1" = "$2}}'
	awk 'BEGIN {found=0 } {if($1=="'$i'"){print $1" = "$2; found=1}} END{if(found!=1){print "#'$i'"}}' $TMP
	if [ "$i" == "innodb_version" -o "$i" == "innodb_max_dirty_pages_pct" -o  \
		"$i" == "innodb_status_output"  -o "$i" == "innodb_write_io_threads"  -o \
		"$i" == "innodb_io_capacity_max"  -o "$i" == "innodb_rollback_on_timeout" ]; then
		echo ""
	fi
done

echo 
