
# agenda:
# migrate CentOS 7 default (latest) MySQL 5.5 to MariaDB 12.3
# create daily partitioning from 2018-01-01 to this day for tables: history_log, history_str, history_text, history_uint, history, trends, trends_uint
# enable automaticall partitioning in future for these 7 tables by using native MariaDB procedures listed
#
# why?:
# http://www.vertabelo.com/blog/technical-articles/everything-you-need-to-know-about-mysql-partitions
#

# steps to produce:
# * stop zabbix-server, zabbix-agent. disable services at startup
# * list/save show create table for all 7 biggest tables
# * backup everything except tables: history, history_uint, history_text, history_str, history_log, trends, trends_uint. https://catonrug.blogspot.com/2018/04/backup-zabbix-database-without-history-mysql.html
# * backup all 7 biggest tables separately
# * remove MySQL 5.5, yum remove mariadb mariadb-server && rm -rf /etc/my.cnf && rm -rf /var/lib/mysql
# * clean yum cache, yum clean all && rm -rf /var/cache/yum
# * install MariaDB repo, https://downloads.mariadb.org/mariadb/repositories/#mirror=nluug&distro=CentOS&distro_release=centos7-amd64--centos7&version=10.3
# * install MariaDB server, yum install MariaDB-server MariaDB-client
# * restore zabbix database which contains no historical date. do not start zabbix-server
# * create table structure for all 5 tables
# * manually create partitions in the past period, https://catonrug.blogspot.com/2018/05/manually-create-partitions-past-period-mysql-zabbix.html
# * create automatic partitioning in the future, https://zabbix.org/wiki/Docs/howto/mysql_partitioning
# * restore all historical data, bzcat dbdump.bz2 | sudo mysql -uzabbix -p zabbix
# * tune MariaDB config
# =======lets start========

# * stop zabbix-server, zabbix-agent. disable services at startup
systemctl stop {zabbix-server,zabbix-agent}
systemctl status {zabbix-server,zabbix-agent}
systemctl disable {zabbix-server,zabbix-agent}

# backup all
time=$(date +%Y%m%d%H%M)
mysqldump -hlocalhost -uroot -p5sRj4GXspvDKsBXW --flush-logs --single-transaction --create-options zabbix | gzip > /root/$time.all.sql.gz


# * list/save show create table for all 7 biggest tables
mysql -u$(grep "^DBUser" /etc/zabbix/zabbix_server.conf|sed "s/^.*=//") -p$(grep "^DBPassword" /etc/zabbix/zabbix_server.conf|sed "s/^.*=//") #authorize in mysql
show create table zabbix.history\G
show create table zabbix.history_uint\G
show create table zabbix.history_str\G
show create table zabbix.history_text\G
show create table zabbix.history_log\G
show create table zabbix.trends\G
show create table zabbix.trends_uint\G

#this will produce. I have to manuallu add ; at the end
CREATE TABLE `history` (
  `itemid` bigint(20) unsigned NOT NULL,
  `clock` int(11) NOT NULL DEFAULT '0',
  `value` double(16,4) NOT NULL DEFAULT '0.0000',
  `ns` int(11) NOT NULL DEFAULT '0',
  KEY `history_1` (`itemid`,`clock`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;
CREATE TABLE `history_uint` (
  `itemid` bigint(20) unsigned NOT NULL,
  `clock` int(11) NOT NULL DEFAULT '0',
  `value` bigint(20) unsigned NOT NULL DEFAULT '0',
  `ns` int(11) NOT NULL DEFAULT '0',
  KEY `history_uint_1` (`itemid`,`clock`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;
CREATE TABLE `history_str` (
  `itemid` bigint(20) unsigned NOT NULL,
  `clock` int(11) NOT NULL DEFAULT '0',
  `value` varchar(255) COLLATE utf8_bin NOT NULL DEFAULT '',
  `ns` int(11) NOT NULL DEFAULT '0',
  KEY `history_str_1` (`itemid`,`clock`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;
CREATE TABLE `history_text` (
  `itemid` bigint(20) unsigned NOT NULL,
  `clock` int(11) NOT NULL DEFAULT '0',
  `value` text COLLATE utf8_bin NOT NULL,
  `ns` int(11) NOT NULL DEFAULT '0',
  KEY `history_text_1` (`itemid`,`clock`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;
CREATE TABLE `history_log` (
  `itemid` bigint(20) unsigned NOT NULL,
  `clock` int(11) NOT NULL DEFAULT '0',
  `timestamp` int(11) NOT NULL DEFAULT '0',
  `source` varchar(64) COLLATE utf8_bin NOT NULL DEFAULT '',
  `severity` int(11) NOT NULL DEFAULT '0',
  `value` text COLLATE utf8_bin NOT NULL,
  `logeventid` int(11) NOT NULL DEFAULT '0',
  `ns` int(11) NOT NULL DEFAULT '0',
  KEY `history_log_1` (`itemid`,`clock`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;
CREATE TABLE `trends` (
  `itemid` bigint(20) unsigned NOT NULL,
  `clock` int(11) NOT NULL DEFAULT '0',
  `num` int(11) NOT NULL DEFAULT '0',
  `value_min` double(16,4) NOT NULL DEFAULT '0.0000',
  `value_avg` double(16,4) NOT NULL DEFAULT '0.0000',
  `value_max` double(16,4) NOT NULL DEFAULT '0.0000',
  PRIMARY KEY (`itemid`,`clock`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;
CREATE TABLE `trends_uint` (
  `itemid` bigint(20) unsigned NOT NULL,
  `clock` int(11) NOT NULL DEFAULT '0',
  `num` int(11) NOT NULL DEFAULT '0',
  `value_min` bigint(20) unsigned NOT NULL DEFAULT '0',
  `value_avg` bigint(20) unsigned NOT NULL DEFAULT '0',
  `value_max` bigint(20) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`itemid`,`clock`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;
exit
# hit ctrl + c to exit the client

# install prerequisite for compression
yum install bzip2 -y

# set timestamp for whole process
time=$(date +%Y%m%d%H%M)

# * backup everything except tables: history, history_uint, history_text, history_str, history_log, trends, trends_uint
sudo mysqldump -uroot -p5sRj4GXspvDKsBXW --flush-logs --single-transaction --create-options --ignore-table=zabbix.history_log --ignore-table=zabbix.history_str --ignore-table=zabbix.history_text --ignore-table=zabbix.history_uint --ignore-table=zabbix.history --ignore-table=zabbix.trends --ignore-table=zabbix.trends_uint zabbix | bzip2 -9 > /root/$time.without.history.trends.bz2

# backup all 7 biggest tablas separatelly.

sudo mysqldump -uroot -p5sRj4GXspvDKsBXW --flush-logs --single-transaction --no-create-db --no-create-info zabbix history_log | bzip2 -9 > /root/$time.history_log.bz2
sudo mysqldump -uroot -p5sRj4GXspvDKsBXW --flush-logs --single-transaction --no-create-db --no-create-info zabbix history_str | bzip2 -9 > /root/$time.history_str.bz2
sudo mysqldump -uroot -p5sRj4GXspvDKsBXW --flush-logs --single-transaction --no-create-db --no-create-info zabbix history_text | bzip2 -9 > /root/$time.history_text.bz2
sudo mysqldump -uroot -p5sRj4GXspvDKsBXW --flush-logs --single-transaction --no-create-db --no-create-info zabbix history_uint | bzip2 -9 > /root/$time.history_uint.bz2
sudo mysqldump -uroot -p5sRj4GXspvDKsBXW --flush-logs --single-transaction --no-create-db --no-create-info zabbix history | bzip2 -9 > /root/$time.history.bz2
sudo mysqldump -uroot -p5sRj4GXspvDKsBXW --flush-logs --single-transaction --no-create-db --no-create-info zabbix trends | bzip2 -9 > /root/$time.trends.bz2
sudo mysqldump -uroot -p5sRj4GXspvDKsBXW --flush-logs --single-transaction --no-create-db --no-create-info zabbix trends_uint | bzip2 -9 > /root/$time.trends_uint.bz2

#list all backup files - there shoud be 8 files and every file should be bigger than 0
ls -lah /root/$time*

# system stop
systemctl stop mariadb
systemctl status mariadb

yum -y remove mariadb mariadb-server
# or if the space lets to do cold backup
mv /var/lib/mysql ~
#rm -rf /var/lib/mysql
mv /etc/my.cnf ~

#create MariaDB repo
#https://downloads.mariadb.org/mariadb/repositories/#mirror=nluug&distro=CentOS&distro_release=centos7-amd64--centos7&version=10.3

cat > /etc/yum.repos.d/MariaDB.repo << EOF
# MariaDB 10.3 CentOS repository list - created 2018-05-31 08:48 UTC
# http://downloads.mariadb.org/mariadb/repositories/
[mariadb]
name = MariaDB
baseurl = http://yum.mariadb.org/10.3/centos7-amd64
gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
gpgcheck=1

EOF

yum clean all
rm -rf /var/cache/yum

yum -y install MariaDB-server MariaDB-client

systemctl start mariadb
systemctl status mariadb
systemctl enable mariadb

#set root password
/usr/bin/mysqladmin -u root password '5sRj4GXspvDKsBXW'

#test if authorization works
mysql -uroot -p'5sRj4GXspvDKsBXW'

#create database 'zabbix', create user 'zabbix' with password 'TaL2gPU5U9FcCU2u'. assign user to database
mysql -h localhost -uroot -p5sRj4GXspvDKsBXW -P 3306 -s <<< 'create database zabbix character set utf8 collate utf8_bin;'
mysql -h localhost -uroot -p5sRj4GXspvDKsBXW -P 3306 -s <<< 'grant all privileges on zabbix.* to zabbix@localhost identified by "TaL2gPU5U9FcCU2u";'
mysql -h localhost -uroot -p5sRj4GXspvDKsBXW -P 3306 -s <<< 'show databases;' | grep zabbix

# create empty tables: history, history_uint, history_text, history_str, history_log, trends, trends_uint
mysql -u$(grep "^DBUser" /etc/zabbix/zabbix_server.conf|sed "s/^.*=//") -p$(grep "^DBPassword" /etc/zabbix/zabbix_server.conf|sed "s/^.*=//")
use zabbix;
CREATE TABLE `history` (
  `itemid` bigint(20) unsigned NOT NULL,
  `clock` int(11) NOT NULL DEFAULT '0',
  `value` double(16,4) NOT NULL DEFAULT '0.0000',
  `ns` int(11) NOT NULL DEFAULT '0',
  KEY `history_1` (`itemid`,`clock`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;
CREATE TABLE `history_uint` (
  `itemid` bigint(20) unsigned NOT NULL,
  `clock` int(11) NOT NULL DEFAULT '0',
  `value` bigint(20) unsigned NOT NULL DEFAULT '0',
  `ns` int(11) NOT NULL DEFAULT '0',
  KEY `history_uint_1` (`itemid`,`clock`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;
CREATE TABLE `history_str` (
  `itemid` bigint(20) unsigned NOT NULL,
  `clock` int(11) NOT NULL DEFAULT '0',
  `value` varchar(255) COLLATE utf8_bin NOT NULL DEFAULT '',
  `ns` int(11) NOT NULL DEFAULT '0',
  KEY `history_str_1` (`itemid`,`clock`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;
CREATE TABLE `history_text` (
  `itemid` bigint(20) unsigned NOT NULL,
  `clock` int(11) NOT NULL DEFAULT '0',
  `value` text COLLATE utf8_bin NOT NULL,
  `ns` int(11) NOT NULL DEFAULT '0',
  KEY `history_text_1` (`itemid`,`clock`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;
CREATE TABLE `history_log` (
  `itemid` bigint(20) unsigned NOT NULL,
  `clock` int(11) NOT NULL DEFAULT '0',
  `timestamp` int(11) NOT NULL DEFAULT '0',
  `source` varchar(64) COLLATE utf8_bin NOT NULL DEFAULT '',
  `severity` int(11) NOT NULL DEFAULT '0',
  `value` text COLLATE utf8_bin NOT NULL,
  `logeventid` int(11) NOT NULL DEFAULT '0',
  `ns` int(11) NOT NULL DEFAULT '0',
  KEY `history_log_1` (`itemid`,`clock`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;
CREATE TABLE `trends` (
  `itemid` bigint(20) unsigned NOT NULL,
  `clock` int(11) NOT NULL DEFAULT '0',
  `num` int(11) NOT NULL DEFAULT '0',
  `value_min` double(16,4) NOT NULL DEFAULT '0.0000',
  `value_avg` double(16,4) NOT NULL DEFAULT '0.0000',
  `value_max` double(16,4) NOT NULL DEFAULT '0.0000',
  PRIMARY KEY (`itemid`,`clock`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;
CREATE TABLE `trends_uint` (
  `itemid` bigint(20) unsigned NOT NULL,
  `clock` int(11) NOT NULL DEFAULT '0',
  `num` int(11) NOT NULL DEFAULT '0',
  `value_min` bigint(20) unsigned NOT NULL DEFAULT '0',
  `value_avg` bigint(20) unsigned NOT NULL DEFAULT '0',
  `value_max` bigint(20) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`itemid`,`clock`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;

# modify tables to enable partitioning

ALTER TABLE `history` PARTITION BY RANGE(clock)
(
PARTITION p2018___OLD VALUES LESS THAN (UNIX_TIMESTAMP("2018-06-01 00:00:00")) ENGINE=InnoDB,
PARTITION p2018_06_01 VALUES LESS THAN (UNIX_TIMESTAMP("2018-06-02 00:00:00")) ENGINE=InnoDB,
PARTITION p2018_06_02 VALUES LESS THAN (UNIX_TIMESTAMP("2018-06-03 00:00:00")) ENGINE=InnoDB,
PARTITION p2018_06_03 VALUES LESS THAN (UNIX_TIMESTAMP("2018-06-04 00:00:00")) ENGINE=InnoDB,
PARTITION p2018_06_04 VALUES LESS THAN (UNIX_TIMESTAMP("2018-06-05 00:00:00")) ENGINE=InnoDB,
PARTITION p2018_06_05 VALUES LESS THAN (UNIX_TIMESTAMP("2018-06-06 00:00:00")) ENGINE=InnoDB,
PARTITION p2018_06_06 VALUES LESS THAN (UNIX_TIMESTAMP("2018-06-07 00:00:00")) ENGINE=InnoDB
);
ALTER TABLE `history_uint` PARTITION BY RANGE(clock)
(
PARTITION p2018___OLD VALUES LESS THAN (UNIX_TIMESTAMP("2018-06-01 00:00:00")) ENGINE=InnoDB,
PARTITION p2018_06_01 VALUES LESS THAN (UNIX_TIMESTAMP("2018-06-02 00:00:00")) ENGINE=InnoDB,
PARTITION p2018_06_02 VALUES LESS THAN (UNIX_TIMESTAMP("2018-06-03 00:00:00")) ENGINE=InnoDB,
PARTITION p2018_06_03 VALUES LESS THAN (UNIX_TIMESTAMP("2018-06-04 00:00:00")) ENGINE=InnoDB,
PARTITION p2018_06_04 VALUES LESS THAN (UNIX_TIMESTAMP("2018-06-05 00:00:00")) ENGINE=InnoDB,
PARTITION p2018_06_05 VALUES LESS THAN (UNIX_TIMESTAMP("2018-06-06 00:00:00")) ENGINE=InnoDB,
PARTITION p2018_06_06 VALUES LESS THAN (UNIX_TIMESTAMP("2018-06-07 00:00:00")) ENGINE=InnoDB
);
ALTER TABLE `history_str` PARTITION BY RANGE(clock)
(
PARTITION p2018___OLD VALUES LESS THAN (UNIX_TIMESTAMP("2018-06-01 00:00:00")) ENGINE=InnoDB,
PARTITION p2018_06_01 VALUES LESS THAN (UNIX_TIMESTAMP("2018-06-02 00:00:00")) ENGINE=InnoDB,
PARTITION p2018_06_02 VALUES LESS THAN (UNIX_TIMESTAMP("2018-06-03 00:00:00")) ENGINE=InnoDB,
PARTITION p2018_06_03 VALUES LESS THAN (UNIX_TIMESTAMP("2018-06-04 00:00:00")) ENGINE=InnoDB,
PARTITION p2018_06_04 VALUES LESS THAN (UNIX_TIMESTAMP("2018-06-05 00:00:00")) ENGINE=InnoDB,
PARTITION p2018_06_05 VALUES LESS THAN (UNIX_TIMESTAMP("2018-06-06 00:00:00")) ENGINE=InnoDB,
PARTITION p2018_06_06 VALUES LESS THAN (UNIX_TIMESTAMP("2018-06-07 00:00:00")) ENGINE=InnoDB
);
ALTER TABLE `history_text` PARTITION BY RANGE(clock)
(
PARTITION p2018___OLD VALUES LESS THAN (UNIX_TIMESTAMP("2018-06-01 00:00:00")) ENGINE=InnoDB,
PARTITION p2018_06_01 VALUES LESS THAN (UNIX_TIMESTAMP("2018-06-02 00:00:00")) ENGINE=InnoDB,
PARTITION p2018_06_02 VALUES LESS THAN (UNIX_TIMESTAMP("2018-06-03 00:00:00")) ENGINE=InnoDB,
PARTITION p2018_06_03 VALUES LESS THAN (UNIX_TIMESTAMP("2018-06-04 00:00:00")) ENGINE=InnoDB,
PARTITION p2018_06_04 VALUES LESS THAN (UNIX_TIMESTAMP("2018-06-05 00:00:00")) ENGINE=InnoDB,
PARTITION p2018_06_05 VALUES LESS THAN (UNIX_TIMESTAMP("2018-06-06 00:00:00")) ENGINE=InnoDB,
PARTITION p2018_06_06 VALUES LESS THAN (UNIX_TIMESTAMP("2018-06-07 00:00:00")) ENGINE=InnoDB
);
ALTER TABLE `history_log` PARTITION BY RANGE(clock)
(
PARTITION p2018___OLD VALUES LESS THAN (UNIX_TIMESTAMP("2018-06-01 00:00:00")) ENGINE=InnoDB,
PARTITION p2018_06_01 VALUES LESS THAN (UNIX_TIMESTAMP("2018-06-02 00:00:00")) ENGINE=InnoDB,
PARTITION p2018_06_02 VALUES LESS THAN (UNIX_TIMESTAMP("2018-06-03 00:00:00")) ENGINE=InnoDB,
PARTITION p2018_06_03 VALUES LESS THAN (UNIX_TIMESTAMP("2018-06-04 00:00:00")) ENGINE=InnoDB,
PARTITION p2018_06_04 VALUES LESS THAN (UNIX_TIMESTAMP("2018-06-05 00:00:00")) ENGINE=InnoDB,
PARTITION p2018_06_05 VALUES LESS THAN (UNIX_TIMESTAMP("2018-06-06 00:00:00")) ENGINE=InnoDB,
PARTITION p2018_06_06 VALUES LESS THAN (UNIX_TIMESTAMP("2018-06-07 00:00:00")) ENGINE=InnoDB
);
ALTER TABLE `trends` PARTITION BY RANGE(clock)
(
PARTITION p2018___OLD VALUES LESS THAN (UNIX_TIMESTAMP("2018-06-01 00:00:00")) ENGINE=InnoDB,
PARTITION p2018_06_01 VALUES LESS THAN (UNIX_TIMESTAMP("2018-06-02 00:00:00")) ENGINE=InnoDB,
PARTITION p2018_06_02 VALUES LESS THAN (UNIX_TIMESTAMP("2018-06-03 00:00:00")) ENGINE=InnoDB,
PARTITION p2018_06_03 VALUES LESS THAN (UNIX_TIMESTAMP("2018-06-04 00:00:00")) ENGINE=InnoDB,
PARTITION p2018_06_04 VALUES LESS THAN (UNIX_TIMESTAMP("2018-06-05 00:00:00")) ENGINE=InnoDB,
PARTITION p2018_06_05 VALUES LESS THAN (UNIX_TIMESTAMP("2018-06-06 00:00:00")) ENGINE=InnoDB,
PARTITION p2018_06_06 VALUES LESS THAN (UNIX_TIMESTAMP("2018-06-07 00:00:00")) ENGINE=InnoDB
);
ALTER TABLE `trends_uint` PARTITION BY RANGE(clock)
(
PARTITION p2018___OLD VALUES LESS THAN (UNIX_TIMESTAMP("2018-06-01 00:00:00")) ENGINE=InnoDB,
PARTITION p2018_06_01 VALUES LESS THAN (UNIX_TIMESTAMP("2018-06-02 00:00:00")) ENGINE=InnoDB,
PARTITION p2018_06_02 VALUES LESS THAN (UNIX_TIMESTAMP("2018-06-03 00:00:00")) ENGINE=InnoDB,
PARTITION p2018_06_03 VALUES LESS THAN (UNIX_TIMESTAMP("2018-06-04 00:00:00")) ENGINE=InnoDB,
PARTITION p2018_06_04 VALUES LESS THAN (UNIX_TIMESTAMP("2018-06-05 00:00:00")) ENGINE=InnoDB,
PARTITION p2018_06_05 VALUES LESS THAN (UNIX_TIMESTAMP("2018-06-06 00:00:00")) ENGINE=InnoDB,
PARTITION p2018_06_06 VALUES LESS THAN (UNIX_TIMESTAMP("2018-06-07 00:00:00")) ENGINE=InnoDB
);

# to modify partition table
# ALTER ONLINE TABLE table REORGANIZE PARTITION;
# https://dev.mysql.com/doc/refman/5.5/en/alter-table-partition-operations.html

#cheeck again if every table has partitioning
show create table zabbix.history\G
show create table zabbix.history_uint\G
show create table zabbix.history_str\G
show create table zabbix.history_text\G
show create table zabbix.history_log\G
show create table zabbix.trends\G
show create table zabbix.trends_uint\G

#logout
exit

# put back data
cd
bzcat $time.without.history.trends.bz2 | sudo mysql -u$(grep "^DBUser" /etc/zabbix/zabbix_server.conf|sed "s/^.*=//") -p$(grep "^DBPassword" /etc/zabbix/zabbix_server.conf|sed "s/^.*=//") zabbix
bzcat $time.history_log.bz2 | sudo mysql -u$(grep "^DBUser" /etc/zabbix/zabbix_server.conf|sed "s/^.*=//") -p$(grep "^DBPassword" /etc/zabbix/zabbix_server.conf|sed "s/^.*=//") zabbix
bzcat $time.history_str.bz2 | sudo mysql -u$(grep "^DBUser" /etc/zabbix/zabbix_server.conf|sed "s/^.*=//") -p$(grep "^DBPassword" /etc/zabbix/zabbix_server.conf|sed "s/^.*=//") zabbix
bzcat $time.history_text.bz2 | sudo mysql -u$(grep "^DBUser" /etc/zabbix/zabbix_server.conf|sed "s/^.*=//") -p$(grep "^DBPassword" /etc/zabbix/zabbix_server.conf|sed "s/^.*=//") zabbix
bzcat $time.history_uint.bz2 | sudo mysql -u$(grep "^DBUser" /etc/zabbix/zabbix_server.conf|sed "s/^.*=//") -p$(grep "^DBPassword" /etc/zabbix/zabbix_server.conf|sed "s/^.*=//") zabbix
bzcat $time.history.bz2 | sudo mysql -u$(grep "^DBUser" /etc/zabbix/zabbix_server.conf|sed "s/^.*=//") -p$(grep "^DBPassword" /etc/zabbix/zabbix_server.conf|sed "s/^.*=//") zabbix
bzcat $time.trends.bz2 | sudo mysql -u$(grep "^DBUser" /etc/zabbix/zabbix_server.conf|sed "s/^.*=//") -p$(grep "^DBPassword" /etc/zabbix/zabbix_server.conf|sed "s/^.*=//") zabbix
bzcat $time.trends_uint.bz2 | sudo mysql -u$(grep "^DBUser" /etc/zabbix/zabbix_server.conf|sed "s/^.*=//") -p$(grep "^DBPassword" /etc/zabbix/zabbix_server.conf|sed "s/^.*=//") zabbix



systemctl enable {zabbix-server,zabbix-agent}
systemctl start {zabbix-server,zabbix-agent}
systemctl status {zabbix-server,zabbix-agent}

# if frontend has thifferent user
grep "DATABASE\|USER\|PASSWORD"  /etc/zabbix/web/zabbix.conf.php

mysql -uroot -p5sRj4GXspvDKsBXW
GRANT SELECT, UPDATE, DELETE, INSERT ON zabbix.* TO 'zabbix_web'@'localhost' identified by 'c$2Q!V4S%R';

SHOW PROCEDURE STATUS;
SHOW EVENTS;

SHOW PROCEDURE STATUS; SHOW EVENTS;
#https://zabbix.org/wiki/Docs/howto/mysql_partitioning

SHOW PROCEDURE STATUS; SHOW EVENTS;
# +--------+---------------------------+-----------+------------------+---------------------+---------------------+---------------+---------+----------------------+----------------------+--------------------+
# | Db     | Name                      | Type      | Definer          | Modified            | Created             | Security_type | Comment | character_set_client | collation_connection | Database Collation |
# +--------+---------------------------+-----------+------------------+---------------------+---------------------+---------------+---------+----------------------+----------------------+--------------------+
# | zabbix | create_next_partitions    | PROCEDURE | zabbix@localhost | 2018-06-04 09:34:57 | 2018-06-04 09:34:57 | DEFINER       |         | utf8                 | utf8_general_ci      | utf8_bin           |
# | zabbix | create_partition_by_day   | PROCEDURE | zabbix@localhost | 2018-06-04 09:35:11 | 2018-06-04 09:35:11 | DEFINER       |         | utf8                 | utf8_general_ci      | utf8_bin           |
# | zabbix | create_partition_by_month | PROCEDURE | zabbix@localhost | 2018-06-04 09:35:17 | 2018-06-04 09:35:17 | DEFINER       |         | utf8                 | utf8_general_ci      | utf8_bin           |
# | zabbix | drop_old_partition        | PROCEDURE | zabbix@localhost | 2018-06-04 09:35:30 | 2018-06-04 09:35:30 | DEFINER       |         | utf8                 | utf8_general_ci      | utf8_bin           |
# | zabbix | drop_partitions           | PROCEDURE | zabbix@localhost | 2018-06-04 09:35:24 | 2018-06-04 09:35:24 | DEFINER       |         | utf8                 | utf8_general_ci      | utf8_bin           |
# +--------+---------------------------+-----------+------------------+---------------------+---------------------+---------------+---------+----------------------+----------------------+--------------------+
# 5 rows in set (0.001 sec)
# 
# +--------+---------------+------------------+-----------+-----------+------------+----------------+----------------+---------------------+------+---------+------------+----------------------+----------------------+--------------------+
# | Db     | Name          | Definer          | Time zone | Type      | Execute at | Interval value | Interval field | Starts              | Ends | Status  | Originator | character_set_client | collation_connection | Database Collation |
# +--------+---------------+------------------+-----------+-----------+------------+----------------+----------------+---------------------+------+---------+------------+----------------------+----------------------+--------------------+
# | zabbix | e_part_manage | zabbix@localhost | SYSTEM    | RECURRING | NULL       | 1              | DAY            | 2011-08-08 04:00:00 | NULL | ENABLED |          1 | utf8                 | utf8_general_ci      | utf8_bin           |
# +--------+---------------+------------------+-----------+-----------+------------+----------------+----------------+---------------------+------+---------+------------+----------------------+----------------------+--------------------+

# how to test the partition task?
mysql -u$(grep "^DBUser" /etc/zabbix/zabbix_server.conf|sed "s/^.*=//") -p$(grep "^DBPassword" /etc/zabbix/zabbix_server.conf|sed "s/^.*=//")
use zabbix;
show create table zabbix.history_uint\G

# *************************** 1. row ***************************
#        Table: history_uint
# Create Table: CREATE TABLE `history_uint` (
#   `itemid` bigint(20) unsigned NOT NULL,
#   `clock` int(11) NOT NULL DEFAULT 0,
#   `value` bigint(20) unsigned NOT NULL DEFAULT 0,
#   `ns` int(11) NOT NULL DEFAULT 0,
#   KEY `history_uint_1` (`itemid`,`clock`)
# ) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin
#  PARTITION BY RANGE (`clock`)
# (PARTITION `p2018___OLD` VALUES LESS THAN (1527811200) ENGINE = InnoDB,
#  PARTITION `p2018_06_01` VALUES LESS THAN (1527897600) ENGINE = InnoDB,
#  PARTITION `p2018_06_02` VALUES LESS THAN (1527984000) ENGINE = InnoDB,
#  PARTITION `p2018_06_03` VALUES LESS THAN (1528070400) ENGINE = InnoDB,
#  PARTITION `p2018_06_04` VALUES LESS THAN (1528156800) ENGINE = InnoDB,
#  PARTITION `p2018_06_05` VALUES LESS THAN (1528243200) ENGINE = InnoDB,
#  PARTITION `p2018_06_06` VALUES LESS THAN (1528329600) ENGINE = InnoDB)

ALTER TABLE history_uint DROP PARTITION p2018_06_06;
ALTER TABLE history_uint DROP PARTITION p2018_06_05;

#ERROR 1318 (42000): Incorrect number of arguments for PROCEDURE zabbix.create_partition_by_day; expected 2, got 1




