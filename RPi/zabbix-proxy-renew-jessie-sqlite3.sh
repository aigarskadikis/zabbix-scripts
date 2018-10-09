#!/bin/bash

#move to supper user
sudo su

#update system
apt-get update -y && apt-get upgrade -y

#install all prerequsites
apt-get install sqlite3 -y #install sqlite3 database engine
apt-get install libsqlite3-dev -y #configure: error: SQLite3 library not found
apt-get install libsnmp-dev -y #configure: error: Invalid Net-SNMP directory - unable to find net-snmp-config
apt-get install libssh2-1-dev -y #configure: error: SSH2 library not found
apt-get install fping -y #/usr/sbin/fping: [2] No such file or directory

#parametrize this script
v=3.4.11
v=$1

#go to ram drive for faster building
cd /dev/shm
curl -L "http://downloads.sourceforge.net/project/zabbix/ZABBIX%20Latest%20Stable/$v/zabbix-$v.tar.gz" -o zabbix-$v.tar.gz
tar -vzxf zabbix-$v.tar.gz -C .
cd zabbix-$v
./configure --enable-proxy --enable-agent --with-sqlite3 --with-libcurl --with-libxml2 --with-ssh2 --with-net-snmp --with-openipmi --with-jabber --with-openssl --with-unixodbc

systemctl status {zabbix-agent,zabbix-proxy}
systemctl stop {zabbix-agent,zabbix-proxy}

existing_version=$(zabbix_proxy -V|egrep -o "[0-9]+\.[0-9]+\.[0-9]+")
mkdir ~/$existing_version

#backup/move zabbix_agentd and zabbix_proxy
cd /usr/local/sbin && mkdir -p ~/$existing_version/$(pwd) && mv * ~/$existing_version/$(pwd)

#backup/move zabbix_sender and zabbix_get
cd /usr/local/bin && mkdir -p ~/$existing_version/$(pwd) && mv zabbix_get ~/$existing_version/$(pwd)
cd /usr/local/bin && mkdir -p ~/$existing_version/$(pwd) && mv zabbix_sender ~/$existing_version/$(pwd)

#make a copy of zabbix_agentd.conf,zabbix_proxy.conf,zabbix_agentd.conf.d,zabbix_proxy.conf.d
cd /usr/local/etc && mkdir -p ~/$existing_version/$(pwd) && cp -R * ~/$existing_version/$(pwd)

cd /etc/init.d && mkdir -p ~/$existing_version/$(pwd) && cp -R zabbix* ~/$existing_version/$(pwd)

cd /dev/shm/zabbix-*
time make install

echo
echo default config file:
grep -v "^#\|^$" /usr/local/etc/zabbix_proxy.conf
echo

# cd /etc/init.d
# rm zabbix-*

#re-read all startup applicaition
systemctl daemon-reload

