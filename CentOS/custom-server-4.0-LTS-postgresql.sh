#!/bin/bash

#this is tested and works together with fresh CentOS-7-x86_64-Minimal-1708.iso
#cd && curl https://raw.githubusercontent.com/catonrug/zabbix-scripts/master/CentOS/custom-server-4.0-LTS-postgresql.sh > install.sh && chmod +x install.sh && time ./install.sh 4.0.2   

#open 80 and 443 into firewall
systemctl enable firewalld
systemctl start firewalld

firewall-cmd --permanent --add-service=http
firewall-cmd --permanent --add-service=https
firewall-cmd --permanent --add-service=mysql
firewall-cmd --add-port=162/udp --permanent
firewall-cmd --add-port=3000/tcp --permanent #for grafana reporting server https://www.digitalocean.com/community/tutorials/how-to-install-and-configure-grafana-to-plot-beautiful-graphs-from-zabbix-on-centos-7
firewall-cmd --add-port=10050/tcp --permanent
firewall-cmd --add-port=10051/tcp --permanent
firewall-cmd --reload

#update system
yum update -y

#install SELinux debuging utils
yum -y install policycoreutils-python bzip2 nmap vim 

# https://www.postgresql.org/download/linux/redhat/

rpm -ivh https://download.postgresql.org/pub/repos/yum/9.5/redhat/rhel-7-x86_64/pgdg-centos95-9.5-3.noarch.rpm

yum -y install postgresql95
yum -y install postgresql95-server

setenforce 0

/usr/pgsql-9.5/bin/postgresql95-setup initdb
systemctl enable postgresql-9.5
systemctl start postgresql-9.5


rpm -ivh http://repo.zabbix.com/zabbix/4.0/rhel/7/x86_64/zabbix-release-4.0-1.el7.noarch.rpm

yum -y install zabbix-server-pgsql zabbix-web-pgsql zabbix-agent

sudo -u postgres dropdb zabbix

sudo -u postgres dropuser zabbix


sudo -u postgres createuser --pwprompt zabbix

sudo -u postgres createdb -O zabbix zabbix

zcat /usr/share/doc/zabbix-server-pgsql*/create.sql.gz | sudo -u zabbix psql zabbix

su - postgres 

DBHost=
DBPassword=zabbix


vim /etc/httpd/conf.d/zabbix.conf

systemctl restart zabbix-server zabbix-agent httpd
systemctl enable zabbix-server zabbix-agent httpd





setsebool -P httpd_can_network_connect on
setsebool -P zabbix_can_network on
