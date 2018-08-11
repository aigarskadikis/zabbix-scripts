#!/bin/bash

#move to supper user
sudo su

#update system
apt-get update -y && apt-get upgrade -y

#after upgrade command must flush the repo again
apt-get update -y

#install all prerequsites
#apt-get install libssl-dev -y #configure: error: OpenSSL library libssl or libcrypto not found
#apt-get install libcurl4-openssl-dev -y #configure: error: Curl library not found
#apt-get install libpcre3-dev -y #configure: error: Unable to use libpcre (libpcre check failed)


#parametrize this script
v=3.4.11
v=$1

#go to ram drive for faster building
cd /dev/shm
curl -L "https://downloads.sourceforge.net/project/zabbix/ZABBIX%20Latest%20Stable/$v/zabbix-$v.tar.gz" -o zabbix-$v.tar.gz
tar -vzxf zabbix-$v.tar.gz -C .
cd zabbix-$v
./configure --enable-agent
#./configure --enable-agent --with-libcurl --with-libxml2 --with-ssh2 --with-openssl
# --with-openssl allow to use encryption between agent and server/proxy

#backup previous version
systemctl status zabbix-agent
systemctl stop zabbix-agent

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

#define a conf file variable
agent=/usr/local/etc/zabbix_agentd.conf

echo
echo default config file:
grep -v "^#\|^$" $agent
echo

groupadd zabbix
useradd -g zabbix zabbix
usermod -a -G video zabbix


ls -l /etc/init.d/zabbix*


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

#set the pid file on ram filesystem
sed -i "s|tmp|dev\/shm|" /etc/init.d/zabbix-agent

#re-read all startup applicaition
systemctl daemon-reload

#enable agent at startup
systemctl enable zabbix-agent

