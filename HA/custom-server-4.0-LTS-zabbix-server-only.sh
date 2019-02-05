#!/bin/bash

#this is tested and works together with fresh CentOS-7-x86_64-Minimal-1708.iso
#cd && curl https://raw.githubusercontent.com/catonrug/zabbix-scripts/master/CentOS/custom-server-4.0-LTS-server-only-without-db.sh > install.sh && chmod +x install.sh && time ./install.sh 4.0.1

#open 80 and 443 into firewall
systemctl enable firewalld
systemctl start firewalld

firewall-cmd --permanent --add-service=http
firewall-cmd --permanent --add-service=https
firewall-cmd --add-port=162/udp --permanent
firewall-cmd --add-port=10051/tcp --permanent
firewall-cmd --reload

#update system
yum -y update

#install SELinux debuging utils
yum -y install policycoreutils-python bzip2 vim nmap

cat <<'EOF'> /etc/yum.repos.d/MariaDB.repo
# http://downloads.mariadb.org/mariadb/repositories/
[mariadb]
name = MariaDB
baseurl = http://yum.mariadb.org/10.3/centos7-amd64
gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
gpgcheck=1
EOF
cat /etc/yum.repos.d/MariaDB.repo

yum makecache fast

#install mariadb (mysql database engine for CentOS 7)
yum -y install MariaDB-client

#show existing databases
mysql -h10.1.10.11 -uzabbix -pzabbix <<< 'show databases;'

#add zabbix 4.0 repository
rpm -ivh http://repo.zabbix.com/zabbix/4.0/rhel/7/x86_64/zabbix-release-4.0-1.el7.noarch.rpm

#install zabbix server which are supposed to use MySQL as a database
yum -y install zabbix-server-mysql

#create zabbix database structure
ls -l /usr/share/doc/zabbix-server-mysql*/
zcat /usr/share/doc/zabbix-server-mysql*/create.sql.gz | mysql -h10.1.10.11 -uzabbix -pzabbix zabbix

systemctl status zabbix-server && systemctl stop zabbix-server

#define server conf file
server=/etc/zabbix/zabbix_server.conf

# configure DBHost
grep "^DBHost=" $server
if [ $? -eq 0 ]; then
sed -i "s/^DBHost=.*/DBHost=10.1.10.11/" $server
else
ln=$(grep -n "DBHost=" $server | egrep -o "^[0-9]+"); ln=$((ln+1))
sed -i "`echo $ln`iDBHost=10.1.10.11" $server
fi

# configure DBPort
grep "^DBPort=" $server
if [ $? -eq 0 ]; then
sed -i "s/^DBPort=.*/DBPort=3306/" $server
else
ln=$(grep -n "DBPort=" $server | egrep -o "^[0-9]+"); ln=$((ln+1))
sed -i "`echo $ln`iDBPort=3306" $server
fi

# configure DBPassword
grep "^DBPassword=" $server
if [ $? -eq 0 ]; then
sed -i "s/^DBPassword=.*/DBPassword=zabbix/" $server #modifies already customized setting
else
ln=$(grep -n "DBPassword=" $server | egrep -o "^[0-9]+"); ln=$((ln+1)) #calculate the the line number after default setting
sed -i "`echo $ln`iDBPassword=zabbix" $server #adds new line
fi

# configure CacheUpdateFrequency
grep "^CacheUpdateFrequency=" $server
if [ $? -eq 0 ]; then
sed -i "s/^CacheUpdateFrequency=.*/CacheUpdateFrequency=4/" $server #modifies already customized setting
else
ln=$(grep -n "CacheUpdateFrequency=" $server | egrep -o "^[0-9]+"); ln=$((ln+1)) #calculate the the line number after default setting
sed -i "`echo $ln`iCacheUpdateFrequency=4" $server #adds new line
fi

#show zabbix server conf file
grep -v "^$\|^#" $server
echo

#restart zabbix server
systemctl start zabbix-server
sleep 1

#output all
cat /var/log/zabbix/zabbix_server.log

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
systemctl disable zabbix-server
