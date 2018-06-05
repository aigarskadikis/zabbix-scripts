#!/bin/bash
# this instruction is supposed to work with
# http://vault.centos.org/4.9/isos/i386/CentOS-4.8-i386-binDVD.torrent
# while going through installation wizard please also select to install 'gcc' and 'make' packages

#backup original repository
cp /etc/yum.repos.d/CentOS-Base.repo ~
#overwrite original repository
curl http://vault.centos.org/4.8/CentOS-Base.repo > /etc/yum.repos.d/CentOS-Base.repo

#update system
yum -y update

#download and extract Zabbix 3.0 agent
cd
wget --no-check-certificate http://downloads.sourceforge.net/project/zabbix/ZABBIX%20Latest%20Stable/3.0.18/zabbix-3.0.18.tar.gz
tar -vzxf zabbix-*.tar.gz -C .
#move to the source
cd zabbix-*
#customize the installation
./configure --enable-agent
#compile
time make install

#point to the Zabbix server
sed -i "s/^Server=.*/Server=10.0.2.5/" /usr/local/etc/zabbix_agentd.conf
sed -i "s/^ServerActive=.*/ServerActive=10.0.2.5/" /usr/local/etc/zabbix_agentd.conf
#set hostname
sed -i "s/^Hostname=.*/Hostname=CentOS4/" /usr/local/etc/zabbix_agentd.conf
#output all custom settings
grep -v "^$\|^#" /usr/local/etc/zabbix_agentd.conf

#create group 'zabbix', create user 'zabbix' and assign it to group 'zabbix'
groupadd zabbix
useradd -g zabbix zabbix

#install startup script
cp ~/zabbix-*/misc/init.d/fedora/core/zabbix_agentd /etc/init.d

#start the agent
/etc/init.d/zabbix_agentd start
#check if agent is running
/etc/init.d/zabbix_agentd status

sleep 1
#look at the log
cat /tmp/zabbix_agentd.log

#enable zabbix agent to lauch at system startup
chkconfig zabbix_agentd on

#reboot the system to see if the agent starts automatically at startup
reboot
