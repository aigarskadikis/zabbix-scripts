# !/bin/bash

# cd && curl https://raw.githubusercontent.com/catonrug/zabbix-scripts/master/CentOS/custom-server-4.2-stable-mariadb-version.sh > install.sh && chmod +x install.sh && time ./install.sh

# open 80 and 443 into firewall
systemctl enable firewalld
systemctl start firewalld

firewall-cmd --permanent --add-service=http
firewall-cmd --permanent --add-service=https
firewall-cmd --add-port=162/udp --permanent
firewall-cmd --add-port=10051/tcp --permanent
firewall-cmd --reload

# update system
yum -y update

# install SELinux debuging utils
yum -y install policycoreutils-python vim nmap

#  install repo
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

yum makecache fast

# install mariadb (mysql database engine for CentOS 7)
yum -y install MariaDB-server MariaDB-client
# this will install database server with no root password
sleep 1

# start mariadb service
systemctl start mariadb
sleep 1

# show existing databases
mysql <<< 'show databases;' | grep zabbix

# create zabbix database
# mysql <<< 'drop database zabbix;'

mysql <<< 'create database zabbix character set utf8 collate utf8_bin;'

# create user zabbix and allow user to connect to the database with only from localhost
mysql <<< 'grant all privileges on zabbix.* to "zabbix"@"localhost" identified by "zabbix";'

# show existing databases
mysql <<< 'show databases;' | grep zabbix

# enable to start MySQL automatically at next boot
systemctl enable mariadb

# add zabbix 4.0 repository
rpm -ivh https://repo.zabbix.com/zabbix/4.2/rhel/7/x86_64/zabbix-release-4.2-1.el7.noarch.rpm

# install zabbix server which are supposed to use MySQL as a database
yum -y install zabbix-server-mysql

# create zabbix database structure
cd /usr/share/doc/zabbix-server-mysql*/
ls -lh
zcat create.sql.gz | mysql zabbix

# create partitions here if necesary

# restore from backup if necesary
# zcat dbdump.bz2 | mysql zabbix
# zcat ~/conf.only.gz | mysql zabbix

# define server conf file
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

# show zabbix server conf file
grep -v "^$\|^#" $server

# start zabbix-server instance
systemctl start zabbix-server

# check if running
systemctl status zabbix-server

# cheeck log file
cat /var/log/zabbix/zabbix_server.log

# enable at startup
systemctl enable zabbix-server

# enable rhel-7-server-optional-rpms repository. This is neccessary to successfully install frontend
yum -y install yum-utils
yum-config-manager --enable rhel-7-server-optional-rpms

# install web server
yum -y install httpd

# install php files
yum -y install zabbix-web-mysql

# check out what is installed
cat /etc/httpd/conf.d/zabbix.conf

# configure timezone
sed -i "s/^.*php_value date.timezone .*$/php_value date.timezone Europe\/Riga/" /etc/httpd/conf.d/zabbix.conf

getsebool -a | grep "httpd_can_network_connect \|zabbix_can_network"
setsebool -P httpd_can_network_connect on
setsebool -P zabbix_can_network on
getsebool -a | grep "httpd_can_network_connect \|zabbix_can_network"

# configure zabbix to host on root
cp /etc/httpd/conf.d/zabbix.conf /etc/httpd/conf.d/zabbix.conf.original

# allow zabbix to be accesible under web root without typing '/zabbix' in the web address
cat << 'EOF' > /etc/httpd/conf.d/zabbix.conf
<VirtualHost *:80>
DocumentRoot /usr/share/zabbix

<Directory "/usr/share/zabbix">
    Options FollowSymLinks
    AllowOverride None
    Require all granted

    <IfModule mod_php5.c>
        php_value max_execution_time 300
        php_value memory_limit 1G
        php_value post_max_size 16M
        php_value upload_max_filesize 20M
        php_value max_input_time 300
        php_value max_input_vars 10000
        php_value always_populate_raw_post_data -1
		php_value date.timezone Europe/Riga
    </IfModule>
</Directory>

<Directory "/usr/share/zabbix/conf">
    Require all denied
</Directory>

<Directory "/usr/share/zabbix/app">
    Require all denied
</Directory>

<Directory "/usr/share/zabbix/include">
    Require all denied
</Directory>

<Directory "/usr/share/zabbix/local">
    Require all denied
</Directory>
</VirtualHost>
EOF

# remove the original web mount
sed -i "s/^/#/g" /etc/httpd/conf.d/welcome.conf

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
\$ZBX_SERVER_NAME = '$(zabbix_server -V | head -1 | grep -o -E "[0-9]+\.[0-9]")';

\$IMAGE_FORMAT_DEFAULT = IMAGE_FORMAT_PNG;
EOF

systemctl restart httpd
systemctl enable httpd

# install agent
yum -y install zabbix-agent zabbix-sender zabbix-get

# define agent conf file
agent=/etc/zabbix/zabbix_agentd.conf

grep "^EnableRemoteCommands=" $agent
if [ $? -eq 0 ]; then
sed -i "s/^EnableRemoteCommands=.*/EnableRemoteCommands=1/" $agent #modifies already customized setting
else
ln=$(grep -n "EnableRemoteCommands=" $agent | egrep -o "^[0-9]+"); ln=$((ln+1)) #calculate the the line number after default setting
sed -i "`echo $ln`iEnableRemoteCommands=1" $agent #adds new line
fi

# start agent now
systemctl start zabbix-agent
cat /var/log/zabbix/zabbix_agentd.log

# enable at startup
systemctl enable zabbix-agent

# install vagrant ssh key
mkdir -p ~/.ssh
echo "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA6NF8iallvQVp22WDkTkyrtvp9eWW6A8YVr+kz4TjGYe7gHzIw+niNltGEFHzD8+v1I2YJ6oXevct1YeS0o9HZyN1Q9qgCgzUFtdOKLv6IedplqoPkcmF0aYet2PkEDo3MlTBckFXPITAMzF8dJSIFo9D8HfdOV0IAdx4O7PtixWKn5y2hMNG0zQPyUecp4pzC6kivAIhyfHilFR61RGL+GPXQ2MWZWFYbAGjyiYJnAmCP3NOTd0jMZEnDkbUvxhMmBYSdETk1rRgm+R4LOzFUGaHqHDLKLX+FIPKcF96hrucXzcWyLbIbEgE98OHlnVYCzRdK8jlqm8tehUc9c9WhQ== vagrant insecure public key"> ~/.ssh/authorized_keys
chmod -R 700 ~/.ssh

# decrease grup screen to 0 seconds
sed -i "s/^GRUB_TIMEOUT=.$/GRUB_TIMEOUT=0/" /etc/default/grub
grub2-mkconfig -o /boot/grub2/grub.cfg

# remove old kerels
yum install -y yum-utils
package-cleanup --oldkernels --count=1 -y
