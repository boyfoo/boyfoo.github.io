---
layout: post
title: 'mysql binlog'
date: 2020-12-20
author: boyfoo
tags: mysql
---

##### 作用

1. 备份恢复依赖二进制日志
2. 主从环境依赖二进制日志

> 默认是没有开启的

##### 配置

```mysql
# 是否开启  1开启 0未开启
mysql> select @@log_bin;
+-----------+
| @@log_bin |
+-----------+
|         1 |
+-----------+

# 日志名称
mysql> select @@log_bin_basename;
+--------------------------+
| @@log_bin_basename       |
+--------------------------+
| /var/log/mysql/mysql-bin |
+--------------------------+

# 服务id 必须要设置，集群中要唯一
mysql> select @@server_id;
+-------------+
| @@server_id |
+-------------+
|           1 |
+-------------+

# 日志格式
mysql> select @@binlog_format;
+-----------------+
| @@binlog_format |
+-----------------+
| ROW             |
+-----------------+

# 双1之二
mysql> select @@sync_binlog;
+---------------+
| @@sync_binlog |
+---------------+
|             1 |
+---------------+
```

使用`log_bin=/var/log/mysql/mysql-bin.log` 直接定路径，等于`log_bin` 加 `log_bin_basename` 两个参数

`binlog`类型：(只有插入更新删除这类语句会受到日志类型影响，类似建表改字段的语句都是 `statement`)
1. `statement`(5.6默认) 语句模式原封不动记录，可读性高，日志量少，但是不严谨
2. `row`(5.6)默认 记录数据行的变化 (正常人看不懂，要分析工具)，日志量大，严谨
3. `mixed`(混合模式) 


##### 日志最小记录单元: 事件

`binlog`中记录日志的最小单元叫做事件

`DDL`,`DCL`操作中 一个语句就是一个事件

对应 `DML` 来说，只记录成功提交的事务，所以都会有一个`begin`和一个`commit`事件，中间一个或多个`DML`事件

如 :
* 事件1 begin;     120 - 340
* 事件2 DML1;      340 - 460
* 事件3 DML2;      460 - 550
* 事件4 commit;    550 - 760

每个事件组成部分:
1. 事件开始标示
2. 事件内容
3. 事件结束标示

开始标示1: at 194

结束位置1: end_log_pos 254

开始标示1: at 254

结束位置1: end_log_pos 340

> 注意上一个结束和下一个开始是同一个数

查看二进制日志：

```mysql
# File_size 文件大小 最后一个事件的截止位置号
mysql> show binary logs;
+----------------------+-----------+
| Log_name             | File_size |
+----------------------+-----------+
| mysql-bin-log.000001 |   3322333 |
+----------------------+-----------+


# 刷一个新的日志文件
mysql> flush logs;
mysql> show binary logs;
+----------------------+-----------+
| Log_name             | File_size |
+----------------------+-----------+
| mysql-bin-log.000001 |   3322384 |
| mysql-bin-log.000002 |       154 |
+----------------------+-----------+

# 查看正在记录的日志 Position 最后一个事件的结束位置
mysql> show master status;
+----------------------+----------+--------------+------------------+-------------------+
| File                 | Position | Binlog_Do_DB | Binlog_Ignore_DB | Executed_Gtid_Set |
+----------------------+----------+--------------+------------------+-------------------+
| mysql-bin-log.000002 |      154 |              |                  |                   |
+----------------------+----------+--------------+------------------+-------------------+


# 查看对应日志文件的事件 一行是一个事件 
# 前两行是自带的头文件信息 至154 位置
mysql> show binlog events in 'mysql-bin-log.000002';
+----------------------+-----+----------------+-----------+-------------+---------------------------------------+
| Log_name             | Pos | Event_type     | Server_id | End_log_pos | Info                                  |
+----------------------+-----+----------------+-----------+-------------+---------------------------------------+
| mysql-bin-log.000002 |   4 | Format_desc    |         1 |         123 | Server ver: 5.7.32-log, Binlog ver: 4 |
| mysql-bin-log.000002 | 123 | Previous_gtids |         1 |         154 |                                       |
| mysql-bin-log.000002 | 154 | Anonymous_Gtid |         1 |         219 | SET @@SESSION.GTID_NEXT= 'ANONYMOUS'  |
| mysql-bin-log.000002 | 219 | Query          |         1 |         293 | BEGIN                                 |
| mysql-bin-log.000002 | 293 | Table_map      |         1 |         390 | table_id: 110 (test01.rxt_exam)       |
| mysql-bin-log.000002 | 390 | Update_rows    |         1 |         758 | table_id: 110 flags: STMT_END_F       |
| mysql-bin-log.000002 | 758 | Xid            |         1 |         789 | COMMIT /* xid=13073 */                |
+----------------------+-----+----------------+-----------+-------------+---------------------------------------+

# 从第219的位置开始 看4条
mysql> show binlog events in 'mysql-bin-log.000002' from 219 limit 4;
```

使用工具查看:

```bash
# 打印的内容可以看到 # at 273 此类标记开始的字符 在修改语句处是一些base64编码的数据
$ mysqlbinlog /var/log/mysql/mysql-bin-log.000002

# 将base64解码查看 
# -vvv 更详细
# 可以看到一些sql 里出现@1 @2 意思是第一列 第二列
$ mysqlbinlog --base64-output=decode-rows -vvv /var/log/mysql/mysql-bin-log.000002

# 指定开始和结束时间
$ mysqlbinlog --start-position=390 --stop-position=789 /var/log/mysql/mysql-bin-log.000002
```

##### 误删库恢复案例

```mysql
mysql> create database binlog charset utf8;
mysql> use binlog;
mysql> create table t1 (id int);
mysql> insert into t1 value(1);
mysql> insert into t1 value(2);
mysql> insert into t1 value(3);
mysql> insert into t1 value(4);
mysql> insert into t1 value(5);
mysql> drop database binlog;
```

开始恢复:
1. 截取建库的位置

先查看当前日志
```mysql
mysql> show master status;
+----------------------+----------+--------------+------------------+-------------------+
| File                 | Position | Binlog_Do_DB | Binlog_Ignore_DB | Executed_Gtid_Set |
+----------------------+----------+--------------+------------------+-------------------+
| mysql-bin-log.000002 |     2745 |              |                  |                   |
+----------------------+----------+--------------+------------------+-------------------+
```
退出到命令行执行:

```bash
# 得到开始位置 1017
$ mysql -uroot -proot -e "show binlog events in 'mysql-bin-log.000002'" | grep "create database binlog charset utf8";
mysql-bin-log.000002	1017	Query	1	1130	create database binlog charset utf8
```

2. 截取删库的位置

```bash
# 得到删除的位置 2647 
$ mysql -uroot -proot -e "show binlog events in 'mysql-bin-log.000002'" | grep "drop database binlog";
mysql-bin-log.000002	2647	Query	1	2745	drop database binlog
```

3. 导出日志到sql文件
```bash
$ mysqlbinlog --start-position=1017 --stop-position=2647 /var/log/mysql/mysql-bin-log.000002 > /var/log/mysql/test.sql
```

4. 导入sql文件到数据库

```mysql
# 导入也会产生二进制日志 先临时关闭 !!!!!!!!!!!!!!!
mysql> set sql_log_bin=0;
mysql> source /var/log/mysql/test.sql;
mysql> set sql_log_bin=1;
```


##### binlog gtid管理

`gtid`对每一个事务打了一个标签，更清晰标记了每一个操作，不需要再去关系开始位置和结束位置`position`

`gtid`是前面是服务唯一`id`使用`:`拼接上唯一事务`id`，之后的事务`id`会是连续的:

```bash
71fe8ba8-3940-11eb-ac7e-0242ac1a0002:1
```

```bash
# 开启
gtid-mode=on
# 启动强制GTID的一致性
enforce-gtid-consistency=true
```

当发送修改后查看

```mysql
# Executed_Gtid_Set 记录了gtid 当前日志存在的事务id是 1到10
mysql> show master status;
+----------------------+----------+--------------+------------------+------------------------------------------+
| File                 | Position | Binlog_Do_DB | Binlog_Ignore_DB | Executed_Gtid_Set                        |
+----------------------+----------+--------------+------------------+------------------------------------------+
| mysql-bin-log.000003 |      668 |              |                  | 71fe8ba8-3940-11eb-ac7e-0242ac1a0002:1-10|
+----------------------+----------+--------------+------------------+------------------------------------------+
```

截取 `gtid` 生成`sql`：

```bash
# 导出事务id 2 到 5 的sql
mysqlbinlog --skip-gtids --include-gtids='71fe8ba8-3940-11eb-ac7e-0242ac1a0002:2-5' /var/log/mysql/mysql-bin-log.000003 > test02.sql

# 导出事务id 2 到 10 的sql 过率第4个 he1 第7个 
mysqlbinlog --skip-gtids --include-gtids='71fe8ba8-3940-11eb-ac7e-0242ac1a0002:2-5' --exclude-gtids='71fe8ba8-3940-11eb-ac7e-0242ac1a0002:4,71fe8ba8-3940-11eb-ac7e-0242ac1a0002:7'  /var/log/mysql/mysql-bin-log.000003 > test02.sql
```

`--skip-gtids` 作用，因为`gtid`自带幂等性检查，就是已经执行过的`gtid`再执行时不会执行会直接跳过，主要用于主从复制的时候防止反复执行，但在恢复的时候需要执行之前的，加上`--skip-gtids`在执行的时候不会去检查`gtid`幂等性，直接生成新的`gtid`再执行