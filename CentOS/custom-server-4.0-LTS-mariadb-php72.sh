#!/bin/bash

systemctl enable firewalld
systemctl start firewalld

firewall-cmd --permanent --add-service=http
firewall-cmd --permanent --add-service=https
firewall-cmd --add-port=162/udp --permanent
firewall-cmd --add-port=10051/tcp --permanent
firewall-cmd --reload

ver=$1
ver=4.0.5


#update system
yum -y update

#install SELinux debuging utils
yum -y install policycoreutils-python bzip2 vim nmap

# install mariadb repo
cat <<'EOF'> /etc/yum.repos.d/MariaDB.repo
# MariaDB 10.3 CentOS repository list - created 2018-05-31 08:48 UTC
# http://downloads.mariadb.org/mariadb/repositories/
[mariadb]
name = MariaDB
baseurl = http://yum.mariadb.org/10.3/centos7-amd64
gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
gpgcheck=1
EOF
cat /etc/yum.repos.d/MariaDB.repo

# install nginx repo
cat <<'EOF'> /etc/yum.repos.d/nginx.repo
[nginx]
name=nginx repo
baseurl=https://nginx.org/packages/centos/7/$basearch/
gpgcheck=0
enabled=1
EOF
cat /etc/yum.repos.d/nginx.repo

# configure php71 repo
yum -y install http://rpms.remirepo.net/enterprise/remi-release-7.rpm
yum-config-manager --enable remi-php71

yum clean all && rm -rf /var/cache/yum && yum makecache fast

yum search php71

yum -y install php71 php71-php-fpm php71-php-mysqlnd php71-php-opcache php71-php-xml php71-php-xmlrpc php71-php-gd php71-php-mbstring php71-php-json


# install mariadb (mysql database engine for CentOS 7)
yum -y install MariaDB-server MariaDB-client

systemctl start mariadb

#create zabbix database
mysql <<< 'drop database zabbix;'

mysql <<< 'create database zabbix character set utf8 collate utf8_bin;'

#create user zabbix and allow user to connect to the database with only from localhost
mysql <<< 'grant all privileges on zabbix.* to "zabbix"@"localhost" identified by "zabbix";'

#refresh permissions
mysql <<< 'flush privileges;'


#show existing databases
mysql <<< 'show databases;' | grep zabbix

#enable to start MySQL automatically at next boot
systemctl enable mariadb

#add zabbix 4.0 repository
rpm -ivh http://repo.zabbix.com/zabbix/4.0/rhel/7/x86_64/zabbix-release-4.0-1.el7.noarch.rpm

yum -y install zabbix-server-mysql-$ver

ls -l /usr/share/doc/zabbix-server-mysql*/
zcat /usr/share/doc/zabbix-server-mysql*/create.sql.gz | mysql -uzabbix -pzabbix zabbix

# here must be step for partitioning

# override backup
# bzcat dbdump.bz2 | mysql zabbix

# disable selinux
setenforce 0

#define server conf file
server=/etc/zabbix/zabbix_server.conf

grep "^DBPassword=" $server
if [ $? -eq 0 ]; then
sed -i "s/^DBPassword=.*/DBPassword=zabbix/" $server #modifies already customized setting
else
ln=$(grep -n "DBPassword=" $server | egrep -o "^[0-9]+"); ln=$((ln+1)) #calculate the the line number after default setting
sed -i "`echo $ln`iDBPassword=zabbix" $server #adds new line
fi

grep "^CacheUpdateFrequency=" $server
if [ $? -eq 0 ]; then
sed -i "s/^CacheUpdateFrequency=.*/CacheUpdateFrequency=4/" $server #modifies already customized setting
else
ln=$(grep -n "CacheUpdateFrequency=" $server | egrep -o "^[0-9]+"); ln=$((ln+1)) #calculate the the line number after default setting
sed -i "`echo $ln`iCacheUpdateFrequency=4" $server #adds new line
fi

#show zabbix server conf file
grep -v "^$\|^#" $server

#start zabbix-server instance
systemctl start zabbix-server && sleep 1

cat /var/log/zabbix/zabbix_server.log

systemctl status zabbix-server

systemctl enable zabbix-server

#enable rhel-7-server-optional-rpms repository. This is neccessary to successfully install frontend
# yum -y install yum-utils
# yum-config-manager --enable rhel-7-server-optional-rpms

#install zabbix frontend
yum -y install nginx
yum -y install php71-php-fpm
yum -y install zabbix-web-mysql-$ver

systemctl status php71-php-fpm

systemctl start php71-php-fpm

systemctl start nginx 

# remove defaul conf
cp /etc/nginx/conf.d/default.conf ~
rm -rf /etc/nginx/conf.d/default.conf

cd /etc/nginx/conf.d


cat << 'EOF' > zabbix.conf
server {
listen 80;
root /usr/share/zabbix;
access_log /var/log/nginx/zabbix-access.log;
error_log /var/log/nginx/zabbix-error.log;
index index.php index.html index.htm;
location ~ [^/]\.php(/|$) {
fastcgi_split_path_info ^(.+\.php)(/.+)$;
fastcgi_pass unix:/run/php-fpm/php-fpm.sock;
fastcgi_index index.php;
#include fastcgi.conf;
fastcgi_param PHP_VALUE "
max_execution_time = 300
memory_limit = 128M
post_max_size = 16M
upload_max_filesize = 2M
max_input_time = 300
date.timezone = EST
always_populate_raw_post_data = -1
";
}
}
EOF
cat zabbix.conf



systemctl restart php72-php-fpm nginx

systemctl start nginx 


# ln -s /etc/nginx/sites-available/zabbix.conf /etc/nginx/sites-enabled/zabbix.conf


# getsebool -a | grep "httpd_can_network_connect \|zabbix_can_network"
# setsebool -P httpd_can_network_connect on
# setsebool -P zabbix_can_network on
# getsebool -a | grep "httpd_can_network_connect \|zabbix_can_network"

cat > /etc/zabbix/web/zabbix.conf.php << EOF
<?php
// Zabbix GUI configuration file.
global \$DB;

\$DB['TYPE']     = 'MYSQL';
\$DB['SERVER']   = 'localhost';
\$DB['PORT']     = '0';
\$DB['DATABASE'] = 'zabbix';
\$DB['USER']     = 'zabbix';
\$DB['PASSWORD'] = 'zabbix';

// Schema name. Used for IBM DB2 and PostgreSQL.
\$DB['SCHEMA'] = '';

\$ZBX_SERVER      = 'localhost';
\$ZBX_SERVER_PORT = '10051';
\$ZBX_SERVER_NAME = '$1';

\$IMAGE_FORMAT_DEFAULT = IMAGE_FORMAT_PNG;
EOF

systemctl restart httpd
systemctl enable httpd

yum -y install zabbix-agent-$ver

#define agent conf file
agent=/etc/zabbix/zabbix_agentd.conf

grep "^EnableRemoteCommands=" $agent
if [ $? -eq 0 ]; then
sed -i "s/^EnableRemoteCommands=.*/EnableRemoteCommands=1/" $agent #modifies already customized setting
else
ln=$(grep -n "EnableRemoteCommands=" $agent | egrep -o "^[0-9]+"); ln=$((ln+1)) #calculate the the line number after default setting
sed -i "`echo $ln`iEnableRemoteCommands=1" $agent #adds new line
fi

yum install zabbix-sender-$1 -y
yum install zabbix-get-$1 -y
systemctl start zabbix-agent
systemctl enable zabbix-agent

#mysql -h localhost -uroot -p'5sRj4GXspvDKsBXW'
#mysql -u$(grep "^DBUser" /etc/zabbix/zabbix_server.conf|sed "s/^.*=//") -p$(grep "^DBPassword" /etc/zabbix/zabbix_server.conf|sed "s/^.*=//")

grep "comm.*zabbix_server.*zabbix_t" /var/log/audit/audit.log | audit2allow -M comm_zabbix_server_zabbix_t
semodule -i comm_zabbix_server_zabbix_t.pp

setenforce 1

mkdir -p ~/.ssh
echo "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA6NF8iallvQVp22WDkTkyrtvp9eWW6A8YVr+kz4TjGYe7gHzIw+niNltGEFHzD8+v1I2YJ6oXevct1YeS0o9HZyN1Q9qgCgzUFtdOKLv6IedplqoPkcmF0aYet2PkEDo3MlTBckFXPITAMzF8dJSIFo9D8HfdOV0IAdx4O7PtixWKn5y2hMNG0zQPyUecp4pzC6kivAIhyfHilFR61RGL+GPXQ2MWZWFYbAGjyiYJnAmCP3NOTd0jMZEnDkbUvxhMmBYSdETk1rRgm+R4LOzFUGaHqHDLKLX+FIPKcF96hrucXzcWyLbIbEgE98OHlnVYCzRdK8jlqm8tehUc9c9WhQ== vagrant insecure public key"> ~/.ssh/authorized_keys
chmod -R 700 ~/.ssh

yum -y install vim nmap

#decrease grup screen to 0 seconds
sed -i "s/^GRUB_TIMEOUT=.$/GRUB_TIMEOUT=0/" /etc/default/grub
grub2-mkconfig -o /boot/grub2/grub.cfg

# remove old kerels
yum install -y yum-utils
package-cleanup --oldkernels --count=1 -y

