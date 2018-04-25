#!/bin/bash

#make sure the system is works after simple update
yum update -y

#make sure everything works OOB after restart
sudo reboot

#stop zabbix components
systemctl stop {zabbix-server,zabbix-agent}
systemctl status {zabbix-server,zabbix-agent}

#note down password for MySQL user 'zabbix'
grep "DBPassword=" /etc/zabbix/zabbix_server.conf

#make a plain backup of zabbix configuration without any history. this will take less than 10 megabytes.
yum install bzip2 -y
time=$(date +%Y%m%d%H%M)
echo creating mysqldump..
mysqldump -uroot -p --flush-logs --single-transaction --create-options --ignore-table=zabbix.acknowledges --ignore-table=zabbix.alerts --ignore-table=zabbix.auditlog --ignore-table=zabbix.auditlog_details --ignore-table=zabbix.escalations --ignore-table=zabbix.events --ignore-table=zabbix.history --ignore-table=zabbix.history_log --ignore-table=zabbix.history_str --ignore-table=zabbix.history_str_sync --ignore-table=zabbix.history_sync --ignore-table=zabbix.history_text --ignore-table=zabbix.history_uint --ignore-table=zabbix.history_uint_sync --ignore-table=zabbix.profiles --ignore-table=zabbix.service_alarms --ignore-table=zabbix.sessions --ignore-table=zabbix.trends --ignore-table=zabbix.trends_uint --ignore-table=zabbix.user_history --ignore-table=zabbix.node_cksum zabbix | bzip2 -9 > ~/$time.bz2

#stop web server
systemctl stop httpd
#make sure it is stopped
systemctl status httpd

#remove old zabbix repo
yum remove zabbix-release -y

#clean repo cache
yum clean all
rm -rf /var/cache/yum

#temporary disable selinux
setenforce 0

#install new 3.4 repo
rpm -ivh http://repo.zabbix.com/zabbix/3.4/rhel/7/x86_64/zabbix-release-3.4-2.el7.noarch.rpm

#update components
yum update -y

#clear existing zabbix log
> /var/log/zabbix/zabbix_server.log

#start zabbix server
systemctl start zabbix-server
systemctl status zabbix-server

#check if everything is fine
cat /var/log/zabbix/zabbix_server.log

