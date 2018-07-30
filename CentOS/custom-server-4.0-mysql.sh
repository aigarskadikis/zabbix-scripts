#!/bin/bash

#this is tested and works together with fresh CentOS-7-x86_64-Minimal-1708.iso
#cd && curl https://raw.githubusercontent.com/catonrug/zabbix-scripts/master/CentOS/custom-server-4.0-mysql.sh > install.sh && chmod +x install.sh && time ./install.sh

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
yum install policycoreutils-python -y

#install mariadb (mysql database engine for CentOS 7)
yum install mariadb-server -y

#start mariadb service
systemctl start mariadb
if [ $? -ne 0 ]; then
echo cannot start mariadb
else

#set new root password
/usr/bin/mysqladmin -u root password '5sRj4GXspvDKsBXW'
if [ $? -ne 0 ]; then
echo cannot set root password for mariadb
else

#show existing databases
mysql -h localhost -uroot -p5sRj4GXspvDKsBXW -P 3306 -s <<< 'show databases;' | grep zabbix
if [ $? -eq 0 ]; then
echo zabbix database already exist. cannot continue
else
#create zabbix database
mysql -h localhost -uroot -p5sRj4GXspvDKsBXW -P 3306 -s <<< 'create database zabbix character set utf8 collate utf8_bin;'

#create user zabbix and allow user to connect to the database with only from localhost
mysql -h localhost -uroot -p5sRj4GXspvDKsBXW -P 3306 -s <<< 'grant all privileges on zabbix.* to zabbix@localhost identified by "TaL2gPU5U9FcCU2u";'

#create user for partitioning
mysql -h localhost -uroot -p5sRj4GXspvDKsBXW -P 3306 -s <<< 'grant all privileges on zabbix.* to zabbix_part@localhost identified by "dwyQv5X3G6WwtYKg";'

#refresh permissions
mysql -h localhost -uroot -p5sRj4GXspvDKsBXW -P 3306 -s <<< 'flush privileges;'

#show existing databases
mysql -h localhost -uroot -p5sRj4GXspvDKsBXW -P 3306 -s <<< 'show databases;' | grep zabbix

#enable to start MySQL automatically at next boot
systemctl enable mariadb

#add zabbix 3.4 repository
rpm -ivh http://repo.zabbix.com/zabbix/3.5/rhel/7/x86_64/zabbix-release-3.5-1.el7.noarch.rpm
if [ $? -ne 0 ]; then
echo cannot install zabbix repository
else

#install zabbix server which are supposed to use MySQL as a database
yum install zabbix-server-mysql -y
if [ $? -ne 0 ]; then
echo zabbix-server-mysql package not found
else

#create zabbix database structure
ls -l /usr/share/doc/zabbix-server-mysql*/
zcat /usr/share/doc/zabbix-server-mysql*/create.sql.gz | mysql -uzabbix -pTaL2gPU5U9FcCU2u zabbix
if [ $? -ne 0 ]; then
echo cannot insert zabbix sql shema into database
else

systemctl status zabbix-server
if [ $? -eq 3 ]; then
echo zabbix-server service is installed but not stared yet. lets start it now..

setenforce 0

#start zabbix-server instance
systemctl start zabbix-server
#if not started succesfully then check for selinux errors
if [ $? -ne 0 ]; then
grep "denied.*zabbix.*server" /var/log/audit/audit.log | audit2allow -M zabbix_server
semodule -i zabbix_server.pp
fi

systemctl status zabbix-server
if [ $? -eq 0 ]; then
#if service was succesfully started then anable it on next boot
echo enabling zabbix-server to start automatically at next boot
systemctl enable zabbix-server
fi
fi

#empty log file
> /var/log/zabbix/zabbix_server.log

#define server conf file
server=/etc/zabbix/zabbix_server.conf

grep "^DBPassword=" $server
if [ $? -eq 0 ]; then
sed -i "s/^DBPassword=.*/DBPassword=TaL2gPU5U9FcCU2u/" $server #modifies already customized setting
else
ln=$(grep -n "DBPassword=" $server | egrep -o "^[0-9]+"); ln=$((ln+1)) #calculate the the line number after default setting
sed -i "`echo $ln`iDBPassword=TaL2gPU5U9FcCU2u" $server #adds new line
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
echo

#restart zabbix server
systemctl restart zabbix-server
sleep 1

#output all
cat /var/log/zabbix/zabbix_server.log

#enable rhel-7-server-optional-rpms repository. This is neccessary to successfully install frontend
yum install yum-utils -y
yum-config-manager --enable rhel-7-server-optional-rpms

#install zabbix frontend
yum install httpd -y
yum install zabbix-web-mysql -y
#configure timezone
sed -i "s/^.*php_value date.timezone .*$/php_value date.timezone Europe\/Riga/" /etc/httpd/conf.d/zabbix.conf

getsebool -a | grep "httpd_can_network_connect \|zabbix_can_network"
setsebool -P httpd_can_network_connect on
setsebool -P zabbix_can_network on
getsebool -a | grep "httpd_can_network_connect \|zabbix_can_network"

yum -y install policycoreutils-python
cd
curl https://support.zabbix.com/secure/attachment/53320/zabbix_server_add.te > zabbix_server_add.te
checkmodule -M -m -o zabbix_server_add.mod zabbix_server_add.te
semodule_package -m zabbix_server_add.mod -o zabbix_server_add.pp
semodule -i zabbix_server_add.pp

#configure zabbix to host on root
grep "^Alias" /etc/httpd/conf.d/zabbix.conf
if [ $? -ne 0 ]; then
echo Alias not found in "/etc/httpd/conf.d/zabbix.conf". Something is out of order.
else
#replace one line:
#Alias /zabbix /usr/share/zabbix-agent
#with two lines
#<VirtualHost *:80>
#DocumentRoot /usr/share/zabbix
sed -i "s/Alias \/zabbix \/usr\/share\/zabbix/<VirtualHost \*:80>\nDocumentRoot \/usr\/share\/zabbix/" /etc/httpd/conf.d/zabbix.conf

#add to the end of the file:
#</VirtualHost>
grep "</VirtualHost>" /etc/httpd/conf.d/zabbix.conf
if [ $? -eq 0 ]; then
echo "</VirtualHost>" already exists in the file /etc/httpd/conf.d/zabbix.conf
else
echo "</VirtualHost>" >> /etc/httpd/conf.d/zabbix.conf
fi

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
\$DB['PASSWORD'] = 'TaL2gPU5U9FcCU2u';

// Schema name. Used for IBM DB2 and PostgreSQL.
\$DB['SCHEMA'] = '';

\$ZBX_SERVER      = 'localhost';
\$ZBX_SERVER_PORT = '10051';
\$ZBX_SERVER_NAME = '$1';

\$IMAGE_FORMAT_DEFAULT = IMAGE_FORMAT_PNG;
EOF

systemctl restart httpd
systemctl enable httpd

yum install zabbix-agent -y

#define agent conf file
agent=/etc/zabbix/zabbix_agentd.conf

grep "^EnableRemoteCommands=" $agent
if [ $? -eq 0 ]; then
sed -i "s/^EnableRemoteCommands=.*/EnableRemoteCommands=1/" $agent #modifies already customized setting
else
ln=$(grep -n "EnableRemoteCommands=" $agent | egrep -o "^[0-9]+"); ln=$((ln+1)) #calculate the the line number after default setting
sed -i "`echo $ln`iEnableRemoteCommands=1" $agent #adds new line
fi

yum install zabbix-sender -y
yum install zabbix-get -y
systemctl start zabbix-agent
systemctl enable zabbix-agent
fi #httpd document root not configured
fi #cannot insert zabbix sql shema into database
fi #zabbix-server-mysql package not found
fi #cannot install zabbix repository
fi #zabbix database already exist
fi #cannot set root password for mariadb
fi #mariadb is not running

#mysql -h localhost -uroot -p'5sRj4GXspvDKsBXW'
#mysql -u$(grep "^DBUser" /etc/zabbix/zabbix_server.conf|sed "s/^.*=//") -p$(grep "^DBPassword" /etc/zabbix/zabbix_server.conf|sed "s/^.*=//")

mkdir -p ~/.ssh
echo "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA6NF8iallvQVp22WDkTkyrtvp9eWW6A8YVr+kz4TjGYe7gHzIw+niNltGEFHzD8+v1I2YJ6oXevct1YeS0o9HZyN1Q9qgCgzUFtdOKLv6IedplqoPkcmF0aYet2PkEDo3MlTBckFXPITAMzF8dJSIFo9D8HfdOV0IAdx4O7PtixWKn5y2hMNG0zQPyUecp4pzC6kivAIhyfHilFR61RGL+GPXQ2MWZWFYbAGjyiYJnAmCP3NOTd0jMZEnDkbUvxhMmBYSdETk1rRgm+R4LOzFUGaHqHDLKLX+FIPKcF96hrucXzcWyLbIbEgE98OHlnVYCzRdK8jlqm8tehUc9c9WhQ== vagrant insecure public key"> ~/.ssh/authorized_keys
chmod -R 700 ~/.ssh

yum -y install vim nmap

#decrease grup screen to 0 seconds
sed -i "s/^GRUB_TIMEOUT=.$/GRUB_TIMEOUT=0/" /etc/default/grub
grub2-mkconfig -o /boot/grub2/grub.cfg

