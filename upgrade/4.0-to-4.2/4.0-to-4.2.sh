#!/bin/bash

# stop every process which works with database
systemctl stop zabbix-server zabbix-agent httpd zabbix-java-gateway

# make sure zabbix is down
ps aux | grep "[z]abbix"

# remove zabbix repository
yum -y remove zabbix-release

# install 4.2 repo
rpm -Uvh http://repo.zabbix.com/zabbix/4.2/rhel/7/x86_64/zabbix-release-4.2-1.el7.noarch.rpm

# clean and re-create cache
yum clean all && rm -rf /var/cache/yum && yum -y makecache fast

yum update zabbix-*
# this will print output like
# ======================================================================================================================
#  Package                             Arch                   Version                      Repository              Size
# ======================================================================================================================
# Updating:
#  zabbix-agent                        x86_64                 4.2.1-1.el7                  zabbix                 399 k
#  zabbix-get                          x86_64                 4.2.1-1.el7                  zabbix                 285 k
#  zabbix-java-gateway                 x86_64                 4.2.1-1.el7                  zabbix                 759 k
#  zabbix-sender                       x86_64                 4.2.1-1.el7                  zabbix                 297 k
#  zabbix-server-mysql                 x86_64                 4.2.1-1.el7                  zabbix                 2.3 M
#  zabbix-web                          noarch                 4.2.1-1.el7                  zabbix                 2.9 M
#  zabbix-web-mysql                    noarch                 4.2.1-1.el7                  zabbix                 8.8 k
# 
# Transaction Summary
# ======================================================================================================================
# Upgrade  7 Packages

# confirm with y

# clear log
mv /var/log/zabbix/zabbix_server.log ~
# or
> /var/log/zabbix/zabbix_server.log

# if you got a lot of free space. do a cold backup
systemctl stop mysqld
systemctl status mysqld
mkdir -p /root/original
cd /var/lib
time cp -R mysql /home/original
systemctl start mysqld

# execute upgrade
systemctl start zabbix-server

# see if no errors appears
cat /var/log/zabbix/zabbix_server.log

# stop and disable server
systemctl stop zabbix-server zabbix-agent httpd
systemctl disable zabbix-server zabbix-agent httpd

# make sure zabbix is not running
ps aux|grep "[z]abbix"

# start server
systemctl start zabbix-server zabbix-agent httpd zabbix-java-gateway
systemctl enable zabbix-server zabbix-agent httpd zabbix-java-gateway

# see if no errors appears
cat /var/log/zabbix/zabbix_server.log

# update raspberry proxies
cd
wget https://repo.zabbix.com/zabbix/4.2/raspbian/pool/main/z/zabbix-release/zabbix-release_4.2-1+stretch_all.deb
dpkg -i zabbix-release_4.2-1+stretch_all.deb
apt update



