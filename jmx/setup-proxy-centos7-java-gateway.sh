#!/bin/bash

#cd && curl https://raw.githubusercontent.com/catonrug/zabbix-scripts/master/jmx/setup-proxy-centos7-java-gateway.sh > install.sh && chmod +x install.sh && time ./install.sh

#open 80 and 443 into firewall
systemctl enable firewalld && systemctl start firewalld

firewall-cmd --permanent --add-service=http
firewall-cmd --permanent --add-service=https
firewall-cmd --add-port=162/udp --permanent
firewall-cmd --add-port=10051/tcp --permanent
firewall-cmd --reload

#update system
yum -y update

#install SELinux debuging utils
yum -y install policycoreutils-python bzip2 vim nmap

#add zabbix 4.0 repository
rpm -ivh http://repo.zabbix.com/zabbix/4.0/rhel/7/x86_64/zabbix-release-4.0-1.el7.noarch.rpm

#install zabbix server which are supposed to use MySQL as a database
yum -y install zabbix-proxy-sqlite3


systemctl status zabbix-proxy && systemctl stop zabbix-proxy

#define server conf file
server=/etc/zabbix/zabbix_proxy.conf

# configure Server
grep "^Server=" $server
if [ $? -eq 0 ]; then
sed -i "s/^Server=.*/Server=ec2-35-166-97-138.us-west-2.compute.amazonaws.com/" $server
else
ln=$(grep -n "Server=" $server | egrep -o "^[0-9]+"); ln=$((ln+1))
sed -i "`echo $ln`iServer=ec2-35-166-97-138.us-west-2.compute.amazonaws.com" $server
fi

# location for database
grep "^DBName=" $server
if [ $? -eq 0 ]; then
sed -i "s/^DBName=.*/DBName=\/dev\/shm\/zabbix_proxy.sqlite3.db/" $server
else
ln=$(grep -n "DBName=" $server | egrep -o "^[0-9]+"); ln=$((ln+1))
sed -i "`echo $ln`iDBName=\/dev\/shm\/zabbix_proxy.sqlite3.db" $server
fi

# configure CacheUpdateFrequency
grep "^CacheUpdateFrequency=" $server
if [ $? -eq 0 ]; then
sed -i "s/^CacheUpdateFrequency=.*/CacheUpdateFrequency=4/" $server #modifies already customized setting
else
ln=$(grep -n "CacheUpdateFrequency=" $server | egrep -o "^[0-9]+"); ln=$((ln+1)) #calculate the the line number after default setting
sed -i "`echo $ln`iCacheUpdateFrequency=4" $server #adds new line
fi

# configure JavaGateway
grep "^JavaGateway=" $server
if [ $? -eq 0 ]; then
sed -i "s/^JavaGateway=.*/JavaGateway=127.0.0.1/" $server #modifies already customized setting
else
ln=$(grep -n "JavaGateway=" $server | egrep -o "^[0-9]+"); ln=$((ln+1)) #calculate the the line number after default setting
sed -i "`echo $ln`iJavaGateway=127.0.0.1" $server #adds new line
fi

# configure StartJavaPollers
grep "^StartJavaPollers=" $server
if [ $? -eq 0 ]; then
sed -i "s/^StartJavaPollers=.*/StartJavaPollers=1/" $server #modifies already customized setting
else
ln=$(grep -n "StartJavaPollers=" $server | egrep -o "^[0-9]+"); ln=$((ln+1)) #calculate the the line number after default setting
sed -i "`echo $ln`iStartJavaPollers=1" $server #adds new line
fi



#show zabbix server conf file
grep -v "^$\|^#" $server
echo

#restart zabbix server
systemctl start zabbix-proxy
sleep 1

#output all
cat /var/log/zabbix/zabbix_proxy.log

yum -y install zabbix-agent

#define agent conf file
agent=/etc/zabbix/zabbix_agentd.conf

grep "^EnableRemoteCommands=" $agent
if [ $? -eq 0 ]; then
sed -i "s/^EnableRemoteCommands=.*/EnableRemoteCommands=1/" $agent #modifies already customized setting
else
ln=$(grep -n "EnableRemoteCommands=" $agent | egrep -o "^[0-9]+"); ln=$((ln+1)) #calculate the the line number after default setting
sed -i "`echo $ln`iEnableRemoteCommands=1" $agent #adds new line
fi

systemctl start zabbix-agent && systemctl enable zabbix-agent

yum -y install zabbix-sender zabbix-get

# disable zabbix server at startup
systemctl enable zabbix-proxy

yum -y install zabbix-java-gateway
systemctl start zabbix-java-gateway
systemctl enable zabbix-java-gateway

