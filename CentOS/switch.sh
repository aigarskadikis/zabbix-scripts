#!/bin/bash

# stop all components
systemctl stop zabbix-server httpd zabbix-agent

# backup some files
cat /etc/httpd/conf.d/zabbix.conf > ~/zabbix.conf
cat /etc/zabbix/web/zabbix.conf.php > ~/zabbix.conf.php
cat /etc/zabbix/zabbix_server.conf > ~/zabbix_server.conf
cat /etc/zabbix/zabbix_agentd.conf > ~/zabbix_agentd.conf

# remove components
yum -y remove zabbix-web-mysql zabbix-server-mysql zabbix-web zabbix-agent zabbix-get zabbix-sender

# clear and reload yum cache
yum clean all && rm -rf /var/cache/yum && yum makecache

# set the version you are interested
ver=$1

# install specific
yum -y install zabbix-web-mysql-$ver zabbix-server-mysql-$ver zabbix-web-$ver zabbix-agent-$ver zabbix-get-$ver zabbix-sender-$ver

# anable everything at startup
systemctl enable zabbix-server zabbix-agent httpd

# set SELinux off
setenforce 0

# resotre old configs
cat ~/zabbix.conf > /etc/httpd/conf.d/zabbix.conf
cat ~/zabbix.conf.php > /etc/zabbix/web/zabbix.conf.php
# set current version
sed -i "s|ZBX_SERVER_NAME.*$|ZBX_SERVER_NAME = \'$ver\';|" /etc/zabbix/web/zabbix.conf.php
cat ~/zabbix_server.conf > /etc/zabbix/zabbix_server.conf
cat ~/zabbix_agentd.conf > /etc/zabbix/zabbix_agentd.conf

# start components now
systemctl start zabbix-server zabbix-agent httpd
