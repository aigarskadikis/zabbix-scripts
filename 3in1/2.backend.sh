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

# install zabbix 4.0 repository
rpm -Uvh https://repo.zabbix.com/zabbix/4.0/rhel/7/x86_64/zabbix-release-4.0-2.el7.noarch.rpm 

# crean previous yum cache
yum clean all

# create cache
yum makecache

# install some conviences
yum -y install vim net-tools

# install mariadb server
yum -y install MariaDB-client

# install zabbix backend with mysql support + agent, sender and get utility
yum -y install zabbix-server-mysql zabbix-agent zabbix-get zabbix-sender

# look if schema is installed
ls -l /usr/share/doc/zabbix-server-mysql*/

# insert schema to the database 'zabbix' in the database host '10.132.148.248'
zcat /usr/share/doc/zabbix-server-mysql*/create.sql.gz | mysql -h'10.132.148.248' -u'zabbix' -p'zabbix' zabbix

# set database host
sed -i "s|^.*DBHost=.*$|DBHost=10.132.148.248|" /etc/zabbix/zabbix_server.conf

# set database password
sed -i "s|^.*DBPassword=|DBPassword=zabbix|" /etc/zabbix/zabbix_server.conf
grep ^DB /etc/zabbix/zabbix_server.conf

# make sure selinux is off
setenforce 0

# start backend
systemctl start zabbix-server

# make sure its scheduled at startup
systemctl enable zabbix-server

sleep 2

cat /var/log/zabbix/zabbix_server.log
