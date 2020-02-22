#!/bin/bash

# this sequence can be useful only if the database gone corrupted

# backend and database server in this example runs on one server
# backend, frontend, partitioning use the same password to access database

systemctl stop zabbix-server zabbix-agent2 mariadb nginx php-fpm zabbix-java-gateway

ps aux | grep "[z]abbix"

# stop database server
systemctl stop mariadb

# remove database content
rm -rf /var/lib/mysql/*

# start database server
systemctl start mariadb

# create blank database
mysql -e 'create database zabbix character set utf8 collate utf8_bin;'

# obtain the future password from backend file
DBPassword=$(grep ^DBPassword /etc/zabbix/zabbix_server.conf | sed "s%^DBPassword=%%")

# create database with dedicated password
mysql -e "grant all privileges on zabbix.* to zabbix@localhost identified by \"$DBPassword\";"

# insert default schema
cd /usr/share/doc/zabbix-server-mysql
zcat create.sql.gz | mysql -uzabbix -p$DBPassword zabbix

# overwrite from backup
cd
zcat db.conf.zabbix.gz | mysql -uzabbix -p$DBPassword zabbix

# create database partitions
/etc/zabbix/scripts/zabbix_partitioning.py -c /etc/zabbix/zabbix_partitioning.conf -i

# start back components
systemctl start mariadb zabbix-agent2 nginx php-fpm zabbix-server zabbix-java-gateway

