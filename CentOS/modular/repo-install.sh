#!/bin/bash

#add zabbix repository
rpm -ivh http://repo.zabbix.com/zabbix/3.4/rhel/7/x86_64/zabbix-release-3.4-2.el7.noarch.rpm
if [ $? -ne 0 ]; then
echo cannot install zabbix repository
else
