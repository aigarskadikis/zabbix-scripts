#!/bin/bash

#http://zabbix.org/wiki/Install_on_openSUSE_/_SLES

cat /etc/os-release

zypper install gcc make

/sbin/SuSEfirewall2 off

zypper install mysql mysql-client



rcmysql start

mysql_secure_installation


#mysql -u root -pzabbix

mysql -h localhost -uroot -pzabbix -P 3306 -s <<< 'CREATE DATABASE zabbix CHARACTER SET UTF8 collate utf8_bin;'
mysql -h localhost -uroot -pzabbix -P 3306 -s <<< 'GRANT ALL PRIVILEGES on zabbix.* to "zabbix"@"localhost" IDENTIFIED BY "zabbix";'

mysql -h localhost -uroot -pzabbix -P 3306 -s <<< 'show databases;'



wget http://downloads.sourceforge.net/project/zabbix/ZABBIX%20Latest%20Stable/3.4.5/zabbix-3.4.5.tar.gz
tar xvf zabbix-3.4.5.tar.gz

cd ~/zabbix-3.4.5/database/mysql
ls -1
time mysql -uzabbix -pzabbix zabbix < schema.sql
time mysql -uzabbix -pzabbix zabbix < images.sql
time mysql -uzabbix -pzabbix zabbix < data.sql


./configure --enable-server --enable-agent --with-mysql --with-libcurl
zypper install libevent-devel #configure: error: Unable to use libevent (libevent check failed)
zypper install pcre-devel #configure: error: Unable to use libpcre (libpcre check failed)
zypper install curl-devel #configure: error: Curl library not found

./configure --enable-server --enable-agent --with-mysql --with-libcurl --with-libxml2 --with-ssh2
zypper install libxml2-devel #configure: error: LIBXML2 library not found
zypper install libssh2-devel #configure: error: SSH2 library not found

/usr/local/sbin/zabbix_server -c /usr/local/etc/zabbix_server.conf
ps -aux | grep zabbix_server


zypper install httpd

service apache2 start
service apache2 status

cd ~/zabbix-*/frontends/php/

cp -a . /srv/www/htdocs/zabbix


/etc/apache2/conf.d


