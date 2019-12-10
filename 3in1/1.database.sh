#!/bin/bash

# install GPG key
rpm --import http://yum.mariadb.org/RPM-GPG-KEY-MariaDB

# install repositoru
cat <<'EOF'> /etc/yum.repos.d/MariaDB.repo
[mariadb]
name = MariaDB-10.3.16
baseurl=http://yum.mariadb.org/10.3.16/centos7-amd64
# alternative: baseurl=http://archive.mariadb.org/mariadb-10.3.16/yum/centos7-amd64
gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
gpgcheck=1
EOF

# crean previous yum cache
yum clean all

# create cache
yum makecache

# install some conviences
yum -y install vim net-tools

# install mariadb server
yum -y install MariaDB-server MariaDB-client

# make sure database server is down
systemctl stop mariadb

# disable database server
systemctl disable mariadb

# move '/var/lib/mysql' dir to '/data'. '/data' must exist
rsync -av /var/lib/mysql /data

# rename original direcotry
mv /var/lib/mysql /var/lib/mysql.bak

# install zabbix related settings. this file contains the only customizations
cat <<'EOF'> /etc/my.cnf.d/zabbix.cnf
[mysqld]
innodb_buffer_pool_size = 256M
innodb_buffer_pool_instances = 25
innodb_flush_log_at_trx_commit = 0
innodb_flush_method = O_DIRECT
innodb_log_file_size = 64M
query_cache_type = 0
query_cache_size = 0
max_connections = 1000
open_files_limit = 65535
optimizer_switch=index_condition_pushdown=off
bind-address=0.0.0.0
datadir=/data/mysql
socket=/data/mysql/mysql.sock

[client]
port=3306
socket=/data/mysql/mysql.sock
EOF

# if selinux is active then disable it
setenforce 0

# start mariadb server
systemctl start mariadb

# check if data dir is reported correctly
mysql -e 'select @@datadir;'

# check if database server is listening on port any IP address (0.0.0.0) and port 3306
netstat -tulpn|grep 3306

# create database 'zabbix'
mysql -e 'create database zabbix character set utf8 collate utf8_bin;'

# allow backend server to connect to database using username 'zabbix' and password 'zabbix'
mysql -e 'grant all privileges on zabbix.* to "zabbix"@"10.132.150.211" identified by "zabbix"; flush privileges;'

# allow frontend server to connect to database using username 'zabbix' and password 'zabbix'
mysql -e 'grant all privileges on zabbix.* to "zabbix"@"10.132.159.105" identified by "zabbix"; flush privileges;'

# enable at startup
systemctl enable mariadb
