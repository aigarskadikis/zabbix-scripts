#!/bin/bash

#install zabbix server which are supposed to use MySQL as a database
yum install zabbix-server-mysql-$1 -y

#create zabbix database structure
ls -l /usr/share/doc/zabbix-server-mysql*/
zcat /usr/share/doc/zabbix-server-mysql*/create.sql.gz | mysql -uzabbix -pTaL2gPU5U9FcCU2u zabbix
