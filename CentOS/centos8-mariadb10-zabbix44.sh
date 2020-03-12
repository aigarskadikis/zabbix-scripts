#!/bin/bash

# This is a kickstart script which will setup:
# Zabbix server 4.4 on CentOS 8

# if the backup file 'fs.conf.zabbix.tar.gz' is located in current dir
# then based on it's content will setup:
# * database access with same password
# * zabbix java gateway
# * SNMP trap receiver using 'zabbix_trap_receiver.pl'

# an access to internet is required
# the flow may fail if the database password contains '!' or '$'


# add swap space
dd if=/dev/zero of=/myswap bs=1M count=2048
chown root:root /myswap
chmod 0600 /myswap
mkswap /myswap
swapon /myswap
echo '/myswap swap swap defaults 0 0' | sudo tee -a /etc/fstab


# set SELinux to permissive
setenforce 0


# install conveniences
dnf -y install vim nmap strace epel-release

dnf -y install screen

dnf -y install mariadb-server

if [ -f "fs.conf.zabbix.tar.gz" ]; then
tar -vzxf fs.conf.zabbix.tar.gz
fi

# copy SELinux global settings
if [ -f "etc/selinux/config" ]; then
cat etc/selinux/config > /etc/selinux/config
fi


# allow a lot of connections to the database server
mkdir -p /etc/systemd/system/mariadb.service.d
cd /etc/systemd/system/mariadb.service.d
echo -e "[Service]\nLimitNOFILE=65535"> limits.conf
systemctl daemon-reload
# go back to directrory where script is executing
cd -


# populate previous database settings 
if [ -f "etc/my.cnf.d/zabbix.cnf" ]; then
cat etc/my.cnf.d/zabbix.cnf > /etc/my.cnf.d/zabbix.cnf

# otherwise install safe settings which will work on machine with 1GB RAM
else

cd /etc/my.cnf.d
cat << 'EOF' > zabbix.cnf
[server]
 
[mysqld]
innodb_buffer_pool_size = 256M
innodb_buffer_pool_instances = 1
innodb_flush_log_at_trx_commit = 0
innodb_flush_method = O_DIRECT
innodb_log_file_size = 64M
query_cache_type = 0
query_cache_size = 0
max_connections = 2000
optimizer_switch=index_condition_pushdown=off
 
EOF

# go back to previous dir
cd -

fi

systemctl restart mariadb

systemctl enable mariadb

# show live variables inportant to zabbix database
mysql -e 'select @@hostname, @@version, @@datadir, @@innodb_file_per_table, @@skip_name_resolve, @@key_buffer_size, @@max_allowed_packet, @@max_connections, @@join_buffer_size, @@sort_buffer_size, @@read_buffer_size, @@thread_cache_size, @@query_cache_type, @@wait_timeout, @@innodb_buffer_pool_size, @@innodb_log_file_size, @@innodb_log_buffer_size, @@innodb_flush_method, @@innodb_buffer_pool_instances, @@innodb_flush_log_at_trx_commit, @@optimizer_switch\G'


# create a blank database
mysql -e 'create database zabbix character set utf8 collate utf8_bin;'

# detect old dedicated database password
if [ -f "etc/zabbix/zabbix_server.conf" ]; then
DBPassword=$(grep ^DBPassword etc/zabbix/zabbix_server.conf | sed "s%^DBPassword=%%")

# use password 'zabbix'
else
DBPassword=zabbix
fi

# create database
if [ -f "etc/zabbix/zabbix_server.conf" ]; then
mysql -e "grant all privileges on zabbix.* to zabbix@localhost identified by \"$DBPassword\";"
fi


# install zabbix repository
rpm -Uvh https://repo.zabbix.com/zabbix/4.4/rhel/8/x86_64/zabbix-release-4.4-1.el8.noarch.rpm


rpm -Uvh http://mirror.centos.org/centos/8.0.1905/AppStream/x86_64/os/Packages/libssh2-1.8.0-8.module_el8.0.0+189+f9babebb.1.x86_64.rpm


dnf -y install zabbix-server-mysql zabbix-agent2 zabbix-get zabbix-sender

# detect if java-gateway was installed locally before
if [ -f "etc/zabbix/zabbix_server.conf" ]; then
grep ^JavaGateway etc/zabbix/zabbix_server.conf | grep 127.0.0.1
if [ $? -eq 0 ]; then
dnf -y install zabbix-java-gateway
fi
fi


# sync configuration for zabbix-server, zabbix-agent + UserParameter's, java gateway
if [ -d "etc/zabbix" ]; then
rsync -av --delete "etc/zabbix" "/etc"
fi

# enter dir where zabbix schema is located
cd /usr/share/doc/zabbix-server-mysql
zcat create.sql.gz | mysql -uzabbix -p$DBPassword zabbix
# go back to previous dir
cd -

# if there is a custom backup in directory then
if [ -f "db.conf.zabbix.gz" ]; then
zcat db.conf.zabbix.gz | mysql -uzabbix -p$DBPassword zabbix
fi

# if the partitioning script imported from backup then execute it
if [ -f "/etc/zabbix/scripts/zabbix_partitioning.py" ]; then
# install prerequsites for database partitioning
dnf -y install python2
dnf -y install python2-pyyaml
pip2 install mysql-connector-python

# if the configuration exists then create partitions
if [ -f "/etc/zabbix/zabbix_partitioning.conf" ]; then
chmod +x /etc/zabbix/scripts/zabbix_partitioning.py
/etc/zabbix/scripts/zabbix_partitioning.py -c /etc/zabbix/zabbix_partitioning.conf -i

fi

fi

# install SNMP trap support
dnf install -y net-snmp-utils net-snmp

rpm --nodeps -ivh http://repo.okay.com.mx/centos/8/x86_64/release//net-snmp-perl-5.8-7.el8.2.x86_64.rpm

cd /usr/bin
curl -s  https://git.zabbix.com/projects/ZBX/repos/zabbix/raw/misc/snmptrap/zabbix_trap_receiver.pl?at=refs%2Fheads%2Fmaster > zabbix_trap_receiver.pl
chmod +x zabbix_trap_receiver.pl
cd -
 
grep "zabbix_traps.tmp" /usr/bin/zabbix_trap_receiver.pl
 
# if there is a trap configuration from backup, then install allowed communities
if [ -f "etc/snmp/snmptrapd.conf" ]; then
pkdir -p /etc/snmp
cat etc/snmp/snmptrapd.conf > /etc/snmp/snmptrapd.conf

else  
# otherwise install to accept traps from 
cat << 'EOF' > /etc/snmp/snmptrapd.conf
authCommunity execute public
perl do "/usr/bin/zabbix_trap_receiver.pl";
EOF
fi

systemctl enable snmptrapd
systemctl restart snmptrapd

# send test trap
snmptrap -v 1 -c public 127.0.0.1 '.1.3.6.1.6.3.1.1.5.3' '0.0.0.0' 6 33 '55' .1.3.6.1.6.3.1.1.5.3 s "eth0"

# make sure 'zabbix_traps.tmp' exists
ls -l /tmp/zabbix_traps.tmp


if [ -d "var/lib/zabbix" ]; then
rsync -av --delete "var/lib/zabbix" "/var/lib"
chown -R zabbix. /var/lib/zabbix
fi


# populate 'externalscripts' and 'alertscripts'
if [ -d "usr/lib/zabbix" ]; then
rsync -av --delete "usr/lib/zabbix" "/usr/lib"
chown -R zabbix. /usr/lib/zabbix
fi


# restart components
systemctl restart zabbix-server zabbix-agent2 zabbix-java-gateway
systemctl enable zabbix-server zabbix-agent2 zabbix-java-gateway

# install frontend
dnf -y install zabbix-web-mysql zabbix-nginx-conf

# restore nginx conf
if [ -f "etc/nginx/conf.d/zabbix.conf" ]; then
cat etc/nginx/conf.d/zabbix.conf > /etc/nginx/conf.d/zabbix.conf

# otherwise
else

# to determine what is externa IP address
dnf -y install bind-utils
connect=$(dig +short myip.opendns.com @resolver1.opendns.com)

# configure web server to listen on external IP
sed -i "s|^.*listen.*80.*$|listen 80;|1" /etc/nginx/conf.d/zabbix.conf 
sed -i "s|^.*server_name.*example.com.*$|server_name $connect;|1" /etc/nginx/conf.d/zabbix.conf
fi

# restore php fast processor manager. this contains a timezone configuration
if [ -f "etc/php-fpm.d/zabbix.conf" ]; then
cat etc/php-fpm.d/zabbix.conf > /etc/php-fpm.d/zabbix.conf
else

# otherwise pick up timezone configured for system
timezone=$(timedatectl | grep "Time zone" | awk '{ print $3 }')
sed -i "s|^.*php_value.date.timezone.*$|php_value[date.timezone] = $timezone|" /etc/php-fpm.d/zabbix.conf
fi

if [ -f "etc/zabbix/web/zabbix.conf.php" ]; then
cat etc/zabbix/web/zabbix.conf.php > /etc/zabbix/web/zabbix.conf.php

else

cat << 'EOF' > /etc/zabbix/web/zabbix.conf.php
<?php
// Zabbix GUI configuration file.
global $DB;

$DB['TYPE']     = 'MYSQL';
$DB['SERVER']   = '127.0.0.1';
$DB['PORT']     = '0';
$DB['DATABASE'] = 'zabbix';
$DB['USER']     = 'zabbix';
$DB['PASSWORD'] = 'zabbix';

// Schema name. Used for IBM DB2 and PostgreSQL.
$DB['SCHEMA'] = '';

$ZBX_SERVER      = '127.0.0.1';
$ZBX_SERVER_PORT = '10051';
$ZBX_SERVER_NAME = '';

$IMAGE_FORMAT_DEFAULT = IMAGE_FORMAT_PNG;
EOF

fi

systemctl restart nginx php-fpm
systemctl enable nginx php-fpm


if [ -f "etc/crontab" ]; then
cat etc/crontab > /etc/crontab
fi


