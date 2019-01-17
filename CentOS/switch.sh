#!/bin/bash

# stop all components
systemctl systemctl stop zabbix-server httpd zabbix-agent

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
cat /etc/zabbix/zabbix_server.conf.rpmsave > /etc/zabbix/zabbix_server.conf
cat /etc/zabbix/zabbix_agentd.conf.rpmsave > /etc/zabbix/zabbix_agentd.conf

# start components now
systemctl start zabbix-server zabbix-agent httpd

