#!/bin/bash

#this is tested and works together with fresh CentOS-7-x86_64-Minimal-1708.iso
#cd && curl https://raw.githubusercontent.com/catonrug/zabbix-scripts/master/CentOS/custom-server-3.4-mysql.sh > install.sh && chmod +x install.sh && time ./install.sh 3.4.4

./firewall.sh

#update system
yum update -y

#install SELinux debuging utils
yum install policycoreutils-python -y

./mysql.sh

./repo-install.sh $1

./server-install.sh $1

./server-conf.sh

./selinux-policy-install.sh $1

./webserver-install.sh $1

./frontend-conf.sh $1

getsebool -a | grep "httpd_can_network_connect \|zabbix_can_network"
setsebool -P httpd_can_network_connect on
setsebool -P zabbix_can_network on
getsebool -a | grep "httpd_can_network_connect \|zabbix_can_network"

yum install zabbix-agent-$1 -y
yum install zabbix-sender-$1 -y
yum install zabbix-get-$1 -y
systemctl start zabbix-agent
systemctl enable zabbix-agent

