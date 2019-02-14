#!/bin/bash
 
# tested on
# http://vault.centos.org/5.11/isos/i386/CentOS-5.11-i386-bin-DVD-1to2.torrent

# backup original repo
cp /etc/yum.repos.d/CentOS-Base.repo ~

# install working repository
wget -qO- --no-check-certificate https://raw.githubusercontent.com/astj/docker-centos5-vault/master/yum.repos.d/CentOS-Base.repo > /etc/yum.repos.d/CentOS-Base.repo

# update system
yum -y update
 
# make sure gcc is installed
yum -y install gcc
 
# set versions interested
opensslver=1.0.2o
zabbixagentver=2.0.21
 
# make temp dir for zabbix agent project
mkdir /tmp/zabbix_agent
 
# move to the project dir
cd /tmp/zabbix_agent
 
# download openssl package
wget https://www.openssl.org/source/openssl-$opensslver.tar.gz
tar -vzxf openssl-$opensslver.tar.gz -C .
cd openssl-$opensslver
 
# take a look at the last line. this will provide with the architecture name for this system. this can output content like "linux-x86_64"
./config
 
# configure standalone agent. add at the end the architecture type: for example "linux-x86_64"
./Configure no-shared no-threads --prefix=/tmp/zabbix_agent/env linux-x86_64
 
# compile the openssl
time make install
 
# take a look what has been installed. yum -y install tree
tree /tmp/zabbix_agent/env

# download agent
wget --no-check-certificate http://downloads.sourceforge.net/project/zabbix/ZABBIX%20Latest%20Stable/$zabbixagentver/zabbix-$zabbixagentver.tar.gz
tar -vzxf zabbix-$zabbixagentver.tar.gz -C .
cd zabbix-$zabbixagentver
./configure --enable-agent no-shared --prefix=/ --sysconfdir=/etc/zabbix --with-openssl=/tmp/zabbix_agent/env
time make install
 
# test if anything is working
 
# create group and user
groupadd zabbix
useradd -g zabbix zabbix
 
# go under user 'zabbix'
su zabbix -s /bin/bash
 
# execute the agent
zabbix_agentd -c /etc/zabbix/zabbix_agentd.conf -f
 
# appendix
# with openssl version 1.1.0h there will be error:
# Perl v5.10.0 required--this is only v5.8.8
