#!/bin/bash

getenforce

systemctl status zabbix-server

setenforce 0

curl https://support.zabbix.com/secure/attachment/53320/zabbix_server_add.te > zabbix_server_add.te
checkmodule -M -m -o zabbix_server_add.mod zabbix_server_add.te
semodule_package -m zabbix_server_add.mod -o zabbix_server_add.pp
semodule -i zabbix_server_add.pp

#start zabbix-server instance
systemctl start zabbix-server

sleep 1

grep "denied.*zabbix.*server" /var/log/audit/audit.log | audit2allow -M zabbix_server
semodule -i zabbix_server.pp

systemctl status zabbix-server
systemctl enable zabbix-server

cat /var/log/zabbix/zabbix_server.log

