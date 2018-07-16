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
zabbixagentver=3.0.19

# move to home dir
cd

wget https://www.openssl.org/source/openssl-$opensslver.tar.gz
tar -vzxf openssl-$opensslver.tar.gz -C .
cd openssl-$opensslver

./config
time make install

# move to home dir
cd

wget --no-check-certificate http://downloads.sourceforge.net/project/zabbix/ZABBIX%20Latest%20Stable/$zabbixagentver/zabbix-$zabbixagentver.tar.gz

tar -vzxf zabbix-$zabbixagentver.tar.gz -C .
cd zabbix-$zabbixagentver
./configure --enable-agent --with-openssl=/usr/local/ssl
time make install

# test if anything is working

# create group and user
groupadd zabbix
useradd -g zabbix zabbix

su zabbix -s /bin/bash

cd /usr/local/sbin

./zabbix_agentd -c ../etc/zabbix_agentd.conf -f

# appendix
# with openssl version 1.1.0h there will be error:
# Perl v5.10.0 required--this is only v5.8.8

