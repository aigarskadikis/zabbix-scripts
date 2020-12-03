#!/bin/bash

rpm -ivh http://repo.zabbix.com/zabbix/4.2/rhel/7/x86_64/zabbix-release-4.2-2.el7.noarch.rpm

rpm -ivh https://dev.mysql.com/get/mysql80-community-release-el7-3.noarch.rpm

yum -y install mysql-community-client vim

cat << 'EOF' > ~/.my.cnf
[client]
host=10.133.80.228
user=root
password=zabbix
EOF

mysql -e "create database z42test character set utf8 collate utf8_bin;"

yum -y install zabbix-server-mysql zabbix-web-mysql zabbix-agent


zcat /usr/share/doc/zabbix-server-mysql*/create.sql.gz | mysql z42test

systemctl enable zabbix-server zabbix-agent

setenforce 0

systemctl start zabbix-agent

systemctl start zabbix-server

tail -99f /var/log/zabbix/zabbix_server.log

systemctl enable httpd

systemctl start httpd

curl -kLs http://127.0.0.1/zabbix | grep Zabbix

systemctl stop httpd zabbix-server zabbix-agent

ps auxww | grep "[z]abbix"

cd /etc/httpd && mkdir -p ~/backup${PWD} && cp -a * ~/backup${PWD}
cd /etc/zabbix && mkdir -p ~/backup${PWD} && cp -a * ~/backup${PWD}
cd /usr/share/zabbix && mkdir -p ~/backup${PWD} && cp -a * ~/backup${PWD}
cd /usr/lib/zabbix && mkdir -p ~/backup${PWD} && cp -a * ~/backup${PWD}

yum remove 'zabbix-web-*'

yum remove httpd php*

rpm -Uvh https://repo.zabbix.com/zabbix/5.0/rhel/7/x86_64/zabbix-release-5.0-1.el7.noarch.rpm
yum clean all

# upgrade server and agent
yum upgrade 'zabbix-*'

# rename old log to better do the tracking
mv /var/log/zabbix/zabbix_server.log /var/log/zabbix/zabbix_server.log.$(date +%Y%m%d%H%M)
ls -lh /var/log/zabbix

systemctl start zabbix-server

tail -99f /var/log/zabbix/zabbix_server.log


# update GUI
# centos7
yum -y install centos-release-scl

# redhat 7
# yum-config-manager --enable rhel-server-rhscl-7-rpms

vi /etc/yum.repos.d/zabbix.repo

# install 5.0
yum -y install zabbix-web-mysql-scl zabbix-apache-conf-scl


vim /etc/opt/rh/rh-php72/php-fpm.d/zabbix.conf

systemctl start httpd rh-php72-php-fpm

curl -kLs http://127.0.0.1/zabbix | grep Zabbix

systemctl enable httpd rh-php72-php-fpm


systemctl start zabbix-agent 
systemctl enable zabbix-agent
systemctl status zabbix-agent

tail -99f /var/log/zabbix/zabbix_server.log

# go to frontend, clear web browser cache
