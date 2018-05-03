#!/bin/bash

#update
yum update -y

#enable rhel-7-server-optional-rpms repository. This is neccessary to successfully install frontend
yum install yum-utils -y
yum-config-manager --enable rhel-7-server-optional-rpms

#open 80 and 443 into firewall
systemctl enable firewalld
systemctl start firewalld

firewall-cmd --permanent --add-service=http
firewall-cmd --permanent --add-service=https
firewall-cmd --add-port=162/udp --permanent
firewall-cmd --add-port=3000/tcp --permanent #for grafana reporting server https://www.digitalocean.com/community/tutorials/how-to-install-and-configure-grafana-to-plot-beautiful-graphs-from-zabbix-on-centos-7
firewall-cmd --reload

#install SELinux debuging utils
#yum install policycoreutils-python -y
setenforce 0

#install mariadb (mysql database engine for CentOS 7)
yum install mariadb-server -y

#instant start
systemctl start mariadb
echo $?

#set root password
/usr/bin/mysqladmin -u root password '5sRj4GXspvDKsBXW'

#show existing databases
mysql -h localhost -uroot -p5sRj4GXspvDKsBXW -P 3306 -s <<< 'show databases;' | grep zabbix
#create zabbix database
mysql -h localhost -uroot -p5sRj4GXspvDKsBXW -P 3306 -s <<< 'create database zabbix character set utf8 collate utf8_bin;'

#create user zabbix and allow user to connect to the database with only from localhost
mysql -h localhost -uroot -p5sRj4GXspvDKsBXW -P 3306 -s <<< 'grant all privileges on zabbix.* to zabbix@localhost identified by "TaL2gPU5U9FcCU2u";'

#refresh permissions
mysql -h localhost -uroot -p5sRj4GXspvDKsBXW -P 3306 -s <<< 'flush privileges;'

#show existing databases
mysql -h localhost -uroot -p5sRj4GXspvDKsBXW -P 3306 -s <<< 'show databases;' | grep zabbix

#enable to start MySQL automatically at next boot
systemctl enable mariadb

rpm -iv zabbix-server-mysql-*
#error: Failed dependencies:
#        fping is needed by zabbix-server-mysql-3.4.8-0.0.1r78441.el7.x86_64
#        libOpenIPMI.so.0()(64bit) is needed by zabbix-server-mysql-3.4.8-0.0.1r78441.el7.x86_64
#        libOpenIPMIposix.so.0()(64bit) is needed by zabbix-server-mysql-3.4.8-0.0.1r78441.el7.x86_64
#        libevent-2.0.so.5()(64bit) is needed by zabbix-server-mysql-3.4.8-0.0.1r78441.el7.x86_64
#        libiksemel.so.3()(64bit) is needed by zabbix-server-mysql-3.4.8-0.0.1r78441.el7.x86_64
#        libnetsnmp.so.31()(64bit) is needed by zabbix-server-mysql-3.4.8-0.0.1r78441.el7.x86_64
#        libodbc.so.2()(64bit) is needed by zabbix-server-mysql-3.4.8-0.0.1r78441.el7.x86_64

rpm -ivh https://repo.zabbix.com/non-supported/rhel/7/x86_64/fping-3.10-1.el7.x86_64.rpm
yum install OpenIPMI-libs libevent net-snmp-libs unixODBC -y

## rpm -ivh https://repo.zabbix.com/non-supported/rhel/7/x86_64/iksemel-devel-1.4-2.el7.centos.x86_64.rpm
#error: Failed dependencies:
#        gnutls-devel is needed by iksemel-devel-1.4-2.el7.centos.x86_64
#        iksemel = 1.4-2.el7.centos is needed by iksemel-devel-1.4-2.el7.centos.x86_64
#        libiksemel.so.3()(64bit) is needed by iksemel-devel-1.4-2.el7.centos.x86_64
## rpm -ivh https://repo.zabbix.com/non-supported/rhel/7/x86_64/iksemel-1.4-2.el7.centos.x86_64.rpm
#Retrieving https://repo.zabbix.com/non-supported/rhel/7/x86_64/iksemel-1.4-2.el7.centos.x86_64.rpm
#error: Failed dependencies:
#        libgnutls.so.28()(64bit) is needed by iksemel-1.4-2.el7.centos.x86_64
#        libgnutls.so.28(GNUTLS_1_4)(64bit) is needed by iksemel-1.4-2.el7.centos.x86_64
## rpm -ivh https://repo.zabbix.com/non-supported/rhel/7/x86_64/iksemel-utils-1.4-2.el7.centos.x86_64.rpm
#Retrieving https://repo.zabbix.com/non-supported/rhel/7/x86_64/iksemel-utils-1.4-2.el7.centos.x86_64.rpm
#error: Failed dependencies:
#        iksemel = 1.4-2.el7.centos is needed by iksemel-utils-1.4-2.el7.centos.x86_64
#        libgnutls.so.28()(64bit) is needed by iksemel-utils-1.4-2.el7.centos.x86_64
#        libiksemel.so.3()(64bit) is needed by iksemel-utils-1.4-2.el7.centos.x86_64

yum install gnutls-devel -y
rpm -ivh https://repo.zabbix.com/non-supported/rhel/7/x86_64/iksemel-1.4-2.el7.centos.x86_64.rpm
rpm -ivh https://repo.zabbix.com/non-supported/rhel/7/x86_64/iksemel-devel-1.4-2.el7.centos.x86_64.rpm
rpm -ivh https://repo.zabbix.com/non-supported/rhel/7/x86_64/iksemel-utils-1.4-2.el7.centos.x86_64.rpm


rpm -iv zabbix-server-mysql-*

#create zabbix database structure
ls -l /usr/share/doc/zabbix-server-mysql*/
zcat /usr/share/doc/zabbix-server-mysql*/create.sql.gz | mysql -uzabbix -pTaL2gPU5U9FcCU2u zabbix

server=/etc/zabbix/zabbix_server.conf
#check if there is existing password line in config
grep "DBPassword=" $server
#change the password
sed -i "s/^.*DBPassword=.*$/DBPassword=TaL2gPU5U9FcCU2u/g" $server

echo "CacheUpdateFrequency=4" >> $server
grep -v "^$\|^#" $server

#start
systemctl start zabbix-server
echo $?

cat /var/log/zabbix/zabbix_server.log

#enable after reboot
systemctl enable zabbix-server

#install web server
yum install httpd -y

#install front end
rpm -iv zabbix-web-3.*
#error: Failed dependencies:
#        dejavu-sans-fonts is needed by zabbix-web
#        php >= 5.4 is needed by zabbix-web
#        php-bcmath is needed by zabbix-web
#        php-gd is needed by zabbix-web
#        php-ldap is needed by zabbix-web
#        php-mbstring is needed by zabbix-web
#        php-xml is needed by zabbix-web
#        zabbix-web-database = 3.4.8-0.0.1r78441.el7 is needed by zabbix-web

yum install dejavu-sans-fonts php php-bcmath php-gd php-ldap php-mbstring php-xml php-mysql -y

rpm -iv zabbix-web-mysql-* zabbix-web-3.*

#set up timezone
sed -i "s/^.*php_value date.timezone .*$/php_value date.timezone Europe\/Riga/" /etc/httpd/conf.d/zabbix.conf

systemctl restart httpd
systemctl status httpd

rpm -iv zabbix-agent-*
systemctl start zabbix-agent
echo $?
systemctl enable zabbix-agent

rpm -iv zabbix-get-*
rpm -iv zabbix-sender-*



