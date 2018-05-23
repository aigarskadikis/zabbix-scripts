#!/bin/bash

#install mariadb (mysql database engine for CentOS 7)
yum install mariadb-server -y

#start mariadb service
systemctl start mariadb
if [ $? -ne 0 ]; then
echo cannot start mariadb
else

#set new root password
/usr/bin/mysqladmin -u root password '5sRj4GXspvDKsBXW'
if [ $? -ne 0 ]; then
echo cannot set root password for mariadb
else

#show existing databases
mysql -h localhost -uroot -p5sRj4GXspvDKsBXW -P 3306 -s <<< 'show databases;' | grep zabbix
if [ $? -eq 0 ]; then
echo zabbix database already exist. cannot continue
else
#create zabbix database
mysql -h localhost -uroot -p5sRj4GXspvDKsBXW -P 3306 -s <<< 'create database zabbix character set utf8 collate utf8_bin;'

#create user zabbix and allow user to connect to the database with only from localhost
mysql -h localhost -uroot -p5sRj4GXspvDKsBXW -P 3306 -s <<< 'grant all privileges on zabbix.* to zabbix@localhost identified by "TaL2gPU5U9FcCU2u";'

#refresh permissions
mysql -h localhost -uroot -p5sRj4GXspvDKsBXW -P 3306 -s <<< 'flush privileges;'

#show existing databases
mysql -h localhost -uroot -p5sRj4GXspvDKsBXW -P 3306 -s <<< 'show databases;' | grep zabbix

#enable to start MySQL automatically at next boot
systemctl enable mariadb
