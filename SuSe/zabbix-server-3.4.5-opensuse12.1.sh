#!/bin/bash

#http://zabbix.org/wiki/Install_on_openSUSE_/_SLES

cat /etc/os-release

zypper install gcc make

/sbin/SuSEfirewall2 off

zypper install mysql mysql-client



rcmysql start

mysql_secure_installation
/usr/bin/mysqladmin -u root password 'zabbix'



mysql -u root -pzabbix
CREATE DATABASE zabbix CHARACTER SET UTF8 collate utf8_bin;
GRANT ALL PRIVILEGES on zabbix.* to "zabbix"@"%" IDENTIFIED BY "zabbix";

mysql -h localhost -uroot -pzabbix -P 3306 -s <<< 'CREATE DATABASE zabbix CHARACTER SET UTF8 collate utf8_bin;'
mysql -h localhost -uroot -pzabbix -P 3306 -s <<< 'GRANT ALL PRIVILEGES on zabbix.* to "zabbix"@"localhost" IDENTIFIED BY "zabbix";'

mysql -h localhost -uroot -pzabbix -P 3306 -s <<< 'FLUSH PRIVILEGES;'

mysql -h localhost -uroot -pzabbix -P 3306 -s <<< 'SHOW GRANTS;'

mysql -h localhost -uroot -pzabbix -P 3306 -s <<< 'show databases;'
show databases;


wget http://downloads.sourceforge.net/project/zabbix/ZABBIX%20Latest%20Stable/3.4.5/zabbix-3.4.5.tar.gz
tar xvf zabbix-3.4.5.tar.gz

cd ~/zabbix-3.4.5/database/mysql
ls -1
time mysql -uzabbix -pzabbix zabbix < schema.sql
time mysql -uzabbix -pzabbix zabbix < images.sql
time mysql -uzabbix -pzabbix zabbix < data.sql


zypper install libevent-devel #configure: error: Unable to use libevent (libevent check failed)
zypper install pcre-devel #configure: error: Unable to use libpcre (libpcre check failed)
zypper install curl-devel #configure: error: Curl library not found
zypper install mysql-devel #configure: error: MySQL library not found
zypper install libxml2-devel #configure: error: LIBXML2 library not found
zypper install libssh2-devel #configure: error: SSH2 library not found
cd ~/zabbix-3.4.5
./configure --enable-server --enable-agent --with-mysql --with-libcurl --with-libxml2 --with-ssh2

time make install

sed -i "s/^.*DBPassword=.*$/DBPassword=zabbix/g" /usr/local/etc/zabbix_server.conf
grep -v "^$\|^#" /usr/local/etc/zabbix_server.conf
/usr/local/sbin/zabbix_server -c /usr/local/etc/zabbix_server.conf
ps -aux | grep zabbix_server


zypper install httpd

service apache2 start
service apache2 status

cd ~/zabbix-*/frontends/php/

cp -a . /srv/www/htdocs/zabbix


/etc/apache2/conf.d

echo "IwojIFphYmJpeCBtb25pdG9yaW5nIHN5c3RlbSBwaHAgd2ViIGZyb250ZW5kCiMKCkFsaWFzIC96YWJiaXggL3Nydi93d3cvaHRkb2NzL3phYmJpeAoKPERpcmVjdG9yeSAiL3Nydi93d3cvaHRkb2NzL3phYmJpeCI+CiAgICBPcHRpb25zIEZvbGxvd1N5bUxpbmtzCiAgICBBbGxvd092ZXJyaWRlIE5vbmUKICAgIE9yZGVyIGFsbG93LGRlbnkKICAgIEFsbG93IGZyb20gYWxsCgogICAgPElmTW9kdWxlIG1vZF9waHA1LmM+CiAgICAgICAgcGhwX3ZhbHVlIG1heF9leGVjdXRpb25fdGltZSAzMDAKICAgICAgICBwaHBfdmFsdWUgbWVtb3J5X2xpbWl0IDEyOE0KICAgICAgICBwaHBfdmFsdWUgcG9zdF9tYXhfc2l6ZSAxNk0KICAgICAgICBwaHBfdmFsdWUgdXBsb2FkX21heF9maWxlc2l6ZSAyTQogICAgICAgIHBocF92YWx1ZSBtYXhfaW5wdXRfdGltZSAzMDAKICAgICAgICBwaHBfdmFsdWUgYWx3YXlzX3BvcHVsYXRlX3Jhd19wb3N0X2RhdGEgLTEKICAgICAgICBwaHBfdmFsdWUgZGF0ZS50aW1lem9uZSBFdXJvcGUvUmlnYQogICAgPC9JZk1vZHVsZT4KPC9EaXJlY3Rvcnk+Cgo8RGlyZWN0b3J5ICIvc3J2L3d3dy9odGRvY3MvemFiYml4L2NvbmYiPgogICAgT3JkZXIgZGVueSxhbGxvdwogICAgRGVueSBmcm9tIGFsbAogICAgPGZpbGVzICoucGhwPgogICAgICAgIE9yZGVyIGRlbnksYWxsb3cKICAgICAgICBEZW55IGZyb20gYWxsCiAgICA8L2ZpbGVzPgo8L0RpcmVjdG9yeT4KCjxEaXJlY3RvcnkgIi9zcnYvd3d3L2h0ZG9jcy96YWJiaXgvYXBwIj4KICAgIE9yZGVyIGRlbnksYWxsb3cKICAgIERlbnkgZnJvbSBhbGwKICAgIDxmaWxlcyAqLnBocD4KICAgICAgICBPcmRlciBkZW55LGFsbG93CiAgICAgICAgRGVueSBmcm9tIGFsbAogICAgPC9maWxlcz4KPC9EaXJlY3Rvcnk+Cgo8RGlyZWN0b3J5ICIvc3J2L3d3dy9odGRvY3MvemFiYml4L2luY2x1ZGUiPgogICAgT3JkZXIgZGVueSxhbGxvdwogICAgRGVueSBmcm9tIGFsbAogICAgPGZpbGVzICoucGhwPgogICAgICAgIE9yZGVyIGRlbnksYWxsb3cKICAgICAgICBEZW55IGZyb20gYWxsCiAgICA8L2ZpbGVzPgo8L0RpcmVjdG9yeT4KCjxEaXJlY3RvcnkgIi9zcnYvd3d3L2h0ZG9jcy96YWJiaXgvbG9jYWwiPgogICAgT3JkZXIgZGVueSxhbGxvdwogICAgRGVueSBmcm9tIGFsbAogICAgPGZpbGVzICoucGhwPgogICAgICAgIE9yZGVyIGRlbnksYWxsb3cKICAgICAgICBEZW55IGZyb20gYWxsCiAgICA8L2ZpbGVzPgo8L0RpcmVjdG9yeT4KCg==" | base64 --decode > /etc/apache2/conf.d/zabbix.conf

service apache2 stop
service apache2 start
service apache2 status

zypper install php5
zypper install php5-devel
zypper install php5-gd
zypper install php5-bcmath
zypper install php5-mysql


zypper search php
zypper install apache2-mod_php5

zypper install apache2-mod_php5 php5 php5-ctype php5-dom php5-iconv php5-json php5-pdo php5-sqlite php5-tokenizer php5-xmlreader php5-xmlwriter

chown -R wwwrun. /srv/www/zabbix


zypper remove apache2-mod_php5 php5 php5-ctype php5-dom php5-iconv php5-json php5-pdo php5-sqlite php5-tokenizer php5-xmlreader php5-xmlwriter php5-devel php5-gd php5-bcmath php5-mysql

#http://download.opensuse.org/repositories/devel:/languages:/php/SLE_12_SP1/x86_64/
#https://software.opensuse.org/download.html?project=devel%3Alanguages%3Aphp&package=php7
zypper addrepo https://download.opensuse.org/repositories/devel:languages:php/openSUSE_Factory/devel:languages:php.repo
zypper refresh
zypper install php7
zypper install apache2-mod_php7

#Problem: nothing provides libc.so.6(GLIBC_2.27)(64bit) needed by php7-7.2.5-129.1.x86_64
# Solution 1: do not install apache2-mod_php7-7.2.5-129.1.x86_64
# Solution 2: break apache2-mod_php7-7.2.5-129.1.x86_64 by ignoring some of its dependencies

#php: error while loading shared libraries: libargon2.so.1: cannot open shared object file: No such file or directory

zypper se -i php7

groupadd zabbixs
useradd -g zabbixs zabbixs

/usr/local/sbin/zabbix_server -c /usr/local/etc/zabbix_server.conf








