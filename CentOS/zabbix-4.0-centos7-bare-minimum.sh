#!/bin/bash
cat /etc/os-release #note the CentOS version
rpm -ivh http://repo.zabbix.com/zabbix/3.5/rhel/7/x86_64/zabbix-release-3.5-1.el7.noarch.rpm #install repository
yum -y install mariadb-server #install database server
systemctl start mariadb && systemctl enable mariadb #start the database server and allow to start it at system (re)boot
/usr/bin/mysqladmin -u root password '5sRj4GXspvDKsBXW' #set password for MySQL user root
mysql -h localhost -uroot -p5sRj4GXspvDKsBXW -P 3306 -s <<< 'create database zabbix character set utf8 collate utf8_bin; grant all privileges on zabbix.* to zabbix@localhost identified by "TaL2gPU5U9FcCU2u"; FLUSH PRIVILEGES;' #create empty zabbix database
yum -y install zabbix-server-mysql #install zabbix back-end with MySQL as the database engine
zcat /usr/share/doc/zabbix-server-mysql*/create.sql.gz | mysql -uzabbix -pTaL2gPU5U9FcCU2u zabbix #create tables and insert data necessary for zabbix database
sed -i "s/^.*DBPassword=.*$/DBPassword=TaL2gPU5U9FcCU2u/" /etc/zabbix/zabbix_server.conf #let zabbix back-end know what is the password for zabbix database
setenforce 0 #turn off SELinux security
systemctl start zabbix-server && systemctl enable zabbix-server #start zabbix-server daemon and allow the service to start automatically after system (re)boot
yum -y install httpd zabbix-web-mysql #install httpd (aka apache), install zabbix profile 
sed -i "s/^.*php_value date.timezone .*$/php_value date.timezone Europe\/Riga/" /etc/httpd/conf.d/zabbix.conf #set time zone
setsebool -P httpd_can_network_connect on && setsebool -P zabbix_can_network on #allow web server to communicate with zabbix daemon
systemctl restart httpd #restart web server
systemctl enable firewalld && systemctl start firewalld #enable and start firewall
firewall-cmd --permanent --add-service=http #open http port to access the web from another host
firewall-cmd --reload && firewall-cmd --list-all
