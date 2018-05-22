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
firewall-cmd --reload


#install SELinux debuging utils
#yum install policycoreutils-python -y
setenforce 0

#install mariadb (mysql database engine for CentOS 7)

#install web server
yum install httpd -y

yum install dejavu-sans-fonts php php-bcmath php-gd php-ldap php-mbstring php-xml php-mysql -y

#install front end
yum install zabbix-web-mysql-3.4.5
#error: Failed dependencies:
#        dejavu-sans-fonts is needed by zabbix-web
#        php >= 5.4 is needed by zabbix-web
#        php-bcmath is needed by zabbix-web
#        php-gd is needed by zabbix-web
#        php-ldap is needed by zabbix-web
#        php-mbstring is needed by zabbix-web
#        php-xml is needed by zabbix-web
#        zabbix-web-database = 3.4.8-0.0.1r78441.el7 is needed by zabbix-web

#set up timezone
sed -i "s/^.*php_value date.timezone .*$/php_value date.timezone Europe\/Riga/" /etc/httpd/conf.d/zabbix.conf

getsebool -a | grep "httpd_can_network_connect \|zabbix_can_network"
setsebool -P httpd_can_network_connect on
setsebool -P zabbix_can_network on
getsebool -a | grep "httpd_can_network_connect \|zabbix_can_network"

yum install policycoreutils-python -y
grep "comm.*httpd.*httpd_t" /var/log/audit/audit.log | audit2allow -M comm_httpd_httpd_t

systemctl restart httpd
systemctl status httpd
systemctl enable httpd

