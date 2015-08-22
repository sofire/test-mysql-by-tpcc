
#测试影响Mysql性能的关键指标

#
http://66note.com/wp/69


##目的：

测试各种关键因素对Mysql性能有多少影响
测试硬件：

DELL CS24–SC 服务器 八核dell服务器
CPU  Intel(R) Xeon(R) CPU  L5420  @ 2.50GHz —  2个 4核 8线程
2个普通SATA硬盘2T  组Raid10 – Hp 的 P400 不带电池
1个金士顿普通的SSD 120G
4*6 共 24G 内存
测试时间：2015.08

## 软件信息：

Centos 6.6 X64
Percona mysql  Ver 14.14 Distrib 5.6.25-73.1, for Linux (x86_64) using  6.0


## 测试软件和方法：

tpcc-mysql

https://www.percona.com/blog/2013/07/01/tpcc-mysql-simple-usage-steps-and-how-to-build-graphs-with-gnuplot/

http://imysql.com/2014/10/10/tpcc-mysql-full-user-manual.shtml

倡议：MySQL压力测试建议基准值(2015试行版）
http://imysql.com/2015/07/28/mysql-benchmark-reference.shtml  

Mysql性能参考：
https://www.percona.com/blog/2014/01/28/10-mysql-settings-to-tune-after-installation/

## 说明

如无特殊说明，tpcc-mysql的参数是：
warehouse100   并发128   预热10分钟   持续30分钟

Mysql参数是：
version = 5.6.25-73.1-log
innodb_version = 5.6.25-73.1
innodb_buffer_pool_size =16G
innodb_log_buffer_size = 67108864
innodb_max_dirty_pages_pct = 75
innodb_data_file_path = ibdata1:1024M:autoextend
innodb_log_file_size = 536870912
innodb_log_files_in_group = 2
innodb_file_per_table = ON
innodb_status_output = OFF
innodb_autoinc_lock_mode = 1
innodb_thread_concurrency = 16
innodb_read_io_threads = 4
innodb_write_io_threads = 4
innodb_flush_method = 
innodb_io_capacity = 200
innodb_io_capacity_max = 2000
tx_isolation = READ-COMMITTED
innodb_flush_log_at_trx_commit = 2
innodb_rollback_on_timeout = OFF
#没启用binlog
sync_binlog =0


## 对比测试1：SSD VS SATA Raid10

结论：SSD的性能 比 SATA机械硬盘好太多，而且也稳定，波动不大


## 测试2：内存对Innodb的影响


结论：Warehouse 100 ，数据容量在10G左右，所以当内存不足 时，ssd也会有性能损失。足够后，性能就差不多了。


## 测试3：数据量测试 (只测试SSD)

结论：数据量直接影响Mysql的性能


## 测试4：事务日志对性能的影响

结论：对性能有一些影响，但不是太大


## 测试5：binlog日志对性能的影响
说明：除了本测试，其他都没有开启binlog日志功能


结论：对性能有小的影响

## 测试：innodb_flush_method 
因为Raid10设备没带电池，不适合做该测试

## 测试：raid10 raid0 raid5等方式
因为条件不够，未做该测试



## 其他记录：
    fast_shutdown=2 ，可快速关闭Mysql。然后重置测试环境。– 数据可能会损坏，启动时会修复；因为是测试，会对数据做恢复。所以可以这样做。
    不用在mysql未关闭的情况下，复制innodb的数据文件