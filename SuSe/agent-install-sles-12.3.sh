#!/bin/bash

#http://zabbix.org/wiki/Install_on_openSUSE_/_SLES

/sbin/SuSEfirewall2 off
cat /etc/os-release
zypper install gcc make

v=3.4.5


wget http://downloads.sourceforge.net/project/zabbix/ZABBIX%20Latest%20Stable/$v/zabbix-$v.tar.gz
tar xvf zabbix-$v.tar.gz

cd ~/zabbix-*

./configure --enable-agent
#configure: error: Unable to use libpcre (libpcre check failed)

cd
wget --no-check-certificate https://ftp.internet.de/pub/linux/suse/sdk12sp2/suse/x86_64/libpcrecpp0-8.33-3.314.x86_64.rpm
zypper install libpcrecpp0-8.33-3.314.x86_64.rpm
wget --no-check-certificate https://ftp.internet.de/pub/linux/suse/sdk12sp2/suse/x86_64/libpcreposix0-8.33-3.314.x86_64.rpm
zypper install libpcreposix0-8.33-3.314.x86_64.rpm


zypper install zabbix-agent-3.4.5-12.2.x86_64.rpm



cd ~/zabbix-*

./configure --enable-agent


#configure: error: Unable to use libpcre (libpcre check failed)
zypper search libpcre

#https://ftp.internet.de/pub/linux/suse/iso/
#SLE-12-SP1-SDK-DVD-x86_64-GM-DVD1.iso
#SLE-12-SP2-SDK-DVD-x86_64-GM-DVD1.iso
#https://ftp.internet.de/pub/linux/suse/sdk12sp2/suse/x86_64/


./configure --enable-agent --with-libcurl --with-libxml2 --with-ssh2

cd
wget --no-check-certificate https://ftp.internet.de/pub/linux/suse/sdk12sp2/suse/x86_64/libpcrecpp0-8.33-3.314.x86_64.rpm
zypper install libpcrecpp0-8.33-3.314.x86_64.rpm
wget --no-check-certificate https://ftp.internet.de/pub/linux/suse/sdk12sp2/suse/x86_64/libpcreposix0-8.33-3.314.x86_64.rpm
zypper install libpcreposix0-8.33-3.314.x86_64.rpm

zypper install zabbix-agent-3.4.5-12.2.x86_64.rpm

 Solution 1: do not install zabbix-agent-3.4.5-12.2.x86_64
 Solution 2: break zabbix-agent-3.4.5-12.2.x86_64 by ignoring some of its dependencies



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




zypper search php
zypper install apache2-mod_php5

zypper install 

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


rcmysql start

rczabbix-agentd start

zabbix-agent start






