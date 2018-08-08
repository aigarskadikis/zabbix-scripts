#!/bin/bash

#move to supper user
sudo su

#update system
apt-get update -y && apt-get upgrade -y

#install all prerequsites
apt-get -y install sqlite3 #install sqlite3 database engine
apt-get -y install libsqlite3-dev #configure: error: SQLite3 library not found
apt-get -y install libsnmp-dev #configure: error: Invalid Net-SNMP directory - unable to find net-snmp-config
apt-get -y install libssh2-1-dev #configure: error: SSH2 library not found
apt-get -y install fping #/usr/sbin/fping: [2] No such file or directory
apt-get -y install libiksemel-dev #configure: error: Jabber library not found
apt-get -y install libxml2-dev #configure: error: LIBXML2 library not found
apt-get -y install unixodbc-dev #configure: error: unixODBC library not found
apt-get -y install libopenipmi-dev #configure: error: Invalid OPENIPMI directory - unable to find ipmiif.h
apt-get -y install libevent-dev #configure: error: Unable to use libevent (libevent check failed)
apt-get -y install libssl-dev #configure: error: OpenSSL library libssl or libcrypto not found
apt-get -y install libcurl4-openssl-dev #configure: error: Curl library not found
apt-get -y install libpcre3-dev #configure: error: Unable to use libpcre (libpcre check failed)
# oir install all together
# apt-get -y install sqlite3 libsqlite3-dev libsnmp-dev libssh2-1-dev fping libiksemel-dev libxml2-dev unixodbc-dev libopenipmi-dev libevent-dev libssl-dev libcurl4-openssl-dev

#parametrize this script
v=3.4.12
v=$1

#go to ram drive for faster building
cd /dev/shm
curl -L "http://downloads.sourceforge.net/project/zabbix/ZABBIX%20Latest%20Stable/$v/zabbix-$v.tar.gz" -o zabbix-$v.tar.gz
tar -vzxf zabbix-$v.tar.gz -C .
cd zabbix-$v
./configure --enable-proxy --enable-agent --with-sqlite3 --with-libcurl --with-libxml2 --with-ssh2 --with-net-snmp --with-openipmi --with-jabber --with-openssl --with-unixodbc

#if the previous process was ok then we are ready to compile and install
#let us stop and backup the previous version
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

cd /dev/shm/zabbix-$v
time make install

echo
echo default config file:
grep -v "^#\|^$" /usr/local/etc/zabbix_proxy.conf
echo


#start zabbix server at reboot
cat > /etc/init.d/zabbix-proxy << EOF
#!/bin/sh
### BEGIN INIT INFO
# Provides:          zabbix-proxy
# Required-Start:    \$remote_fs \$network
# Required-Stop:     \$remote_fs
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Start zabbix-proxy daemon
### END INIT INFO
EOF
grep -v "^#\!\/bin\/sh$" /dev/shm/zabbix-$v/misc/init.d/debian/zabbix-server >> /etc/init.d/zabbix-proxy
sed -i "s/server/proxy/g" /etc/init.d/zabbix-proxy
chmod +x /etc/init.d/zabbix-proxy

#start zabbix agent at reboot
cat > /etc/init.d/zabbix-agent << EOF
#!/bin/sh
### BEGIN INIT INFO
# Provides:          zabbix-agent
# Required-Start:    \$remote_fs \$network
# Required-Stop:     \$remote_fs
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Start zabbix-agent daemon
### END INIT INFO
EOF
grep -v "^#\!\/bin\/sh$" /dev/shm/zabbix-$v/misc/init.d/debian/zabbix-agent >> /etc/init.d/zabbix-agent
chmod +x /etc/init.d/zabbix-agent



#re-read all startup applicaition
systemctl daemon-reload

systemctl start {zabbix-agent,zabbix-proxy}
