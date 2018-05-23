#!/bin/bash

#check if there is existing password line in config
grep "DBPassword=" /etc/zabbix/zabbix_server.conf
if [ $? -eq 0 ]; then
#change the password
sed -i "s/^.*DBPassword=.*$/DBPassword=TaL2gPU5U9FcCU2u/g" /etc/zabbix/zabbix_server.conf
fi

#show zabbix server conf file
grep -v "^$\|^#" /etc/zabbix/zabbix_server.conf
echo
