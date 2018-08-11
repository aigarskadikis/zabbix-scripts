#!/bin/bash

#update system
apt-get -y update

#upgrade os
apt-get -y upgrade

#after upgrade command must flush the repo again
apt-get -y update

#configure: error: Unable to use libpcre (libpcre check failed)
apt-get -y install libpcre3-dev

#parametrize this script
v=3.4.11
v=$1

#go to ram drive for faster building
cd /dev/shm
curl -L "https://downloads.sourceforge.net/project/zabbix/ZABBIX%20Latest%20Stable/$v/zabbix-$v.tar.gz" -o zabbix-$v.tar.gz
tar -vzxf zabbix-$v.tar.gz -C .
cd zabbix-$v
./configure --enable-agent

#move again to dir
cd /dev/shm/zabbix-$v

#compile
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

./agent-config-set.sh ec2-35-166-97-138.us-west-2.compute.amazonaws.com
