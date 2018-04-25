#!/bin/bash

#make sure the system is works after simple update
yum update -y

#enable region
sed -i "s/# php_value date.timezone Europe\/Riga/php_value date.timezone Europe\/Riga/g" /etc/httpd/conf.d/zabbix.conf

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
mysqldump -uroot -p5sRj4GXspvDKsBXW --flush-logs --single-transaction --create-options --ignore-table=zabbix.acknowledges --ignore-table=zabbix.alerts --ignore-table=zabbix.auditlog --ignore-table=zabbix.auditlog_details --ignore-table=zabbix.escalations --ignore-table=zabbix.events --ignore-table=zabbix.history --ignore-table=zabbix.history_log --ignore-table=zabbix.history_str --ignore-table=zabbix.history_str_sync --ignore-table=zabbix.history_sync --ignore-table=zabbix.history_text --ignore-table=zabbix.history_uint --ignore-table=zabbix.history_uint_sync --ignore-table=zabbix.profiles --ignore-table=zabbix.service_alarms --ignore-table=zabbix.sessions --ignore-table=zabbix.trends --ignore-table=zabbix.trends_uint --ignore-table=zabbix.user_history --ignore-table=zabbix.node_cksum zabbix | bzip2 -9 > ~/$time.bz2

#stop web server
systemctl stop httpd

#make sure everything is stopped
systemctl status {zabbix-server,zabbix-agent,httpd}


#remove old zabbix repo
yum remove zabbix-release -y

#clean repo cache
yum clean all
rm -rf /var/cache/yum

#temporary disable selinux
setenforce 0

cp /var/log/zabbix/zabbix_server.log ~
cat ~/zabbix_server.log
> /var/log/zabbix/zabbix_server.log

#install new 3.4 repo
rpm -ivh http://repo.zabbix.com/zabbix/3.4/rhel/7/x86_64/zabbix-release-3.4-2.el7.noarch.rpm

#update components
yum update -y

cat /var/log/zabbix/zabbix_server.log


#start zabbix server
systemctl start zabbix-server & tail -f /var/log/zabbix/zabbix_server.log
#hit ctrl+c to break
systemctl status zabbix-server

#start egaent and front end
systemctl start {zabbix-agent,httpd}

#check how everything is running smoothly 
systemctl status {zabbix-server,zabbix-server,httpd}

#istall some selinux rulles for preprocessing to works
curl -s https://support.zabbix.com/secure/attachment/53320/zabbix_server_add.te > zabbix_server_add.te
checkmodule -M -m -o zabbix_server_add.mod zabbix_server_add.te
semodule_package -m zabbix_server_add.mod -o zabbix_server_add.pp
semodule -i zabbix_server_add.pp

#clear browser cache. Press Ctrl+Shift+Del

#list how many type of selinux denies we have
echo
grep denied /var/log/audit/audit.log | sed "s/^.*denied /denied/g;s/ pid=[0-9]\+ \| ino=[0-9]\+//g;s/ name=.*scontext=\| path=.*scontext=/ /g" | sort | uniq
echo

#ease up installing
grep denied /var/log/audit/audit.log | sed "s/^.*denied /denied/g;s/ pid=[0-9]\+ \| ino=[0-9]\+//g;s/ name=.*scontext=\| path=.*scontext=/ /g" | sort | uniq | sed "s/^.*comm=.//g;s/. .*system_r:/.*/g;s/:.*//g" | sort|uniq | sed "s/^/grep \"comm.*/g;s/$/\" \/var\/log\/audit\/audit.log/g"
echo

#install some rules
grep "comm.*sh.*zabbix_agent_t" /var/log/audit/audit.log | audit2allow -M sh_zabbix_agent_t
semodule -i sh_zabbix_agent_t.pp
grep "comm.*zabbix_server.*zabbix_t" /var/log/audit/audit.log | audit2allow -M zabbix_server_zabbix_t
semodule -i zabbix_server_zabbix_t.pp

#enable selinux
setenforce 1 && tail -f /var/log/audit/audit.log | grep denied

#check if everything is fine
cat /var/log/zabbix/zabbix_server.log

