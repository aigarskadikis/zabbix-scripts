#!/bin/bash

#this is tested and works together with fresh CentOS-7-x86_64-Minimal-1708.iso
#cd && curl https://raw.githubusercontent.com/catonrug/zabbix-scripts/master/CentOS/custom-server-4.0-mysql.sh > install.sh && chmod +x install.sh && time ./install.sh 4.0.0-1.1alpha8

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

#GRANT ALL PRIVILEGES ON *.* TO 'root'@'%'; FLUSH PRIVILEGES;
#GRANT ALL PRIVILEGES ON *.* TO 'root'@'10.0.2.2'; FLUSH PRIVILEGES; SHOW GRANTS;
#SHOW GRANTS FOR 'zabbix'@'10.0.2.2';
#GRANT ALL PRIVILEGES ON *.* TO 'root'@'10.0.2.5'; FLUSH PRIVILEGES; SHOW GRANTS;
#grant all privileges on zabbix.* to 'zabbix'@'%';

#Allow everyone to connect
#mysql -h localhost -uroot -p5sRj4GXspvDKsBXW -P 3306 -s <<< 'grant all privileges on zabbix.* to zabbix@localhost identified by "TaL2gPU5U9FcCU2u";'

#grant all privileges on *.* to 'zabbix'@'10.0.2.2' identified by "TaL2gPU5U9FcCU2u"; FLUSH PRIVILEGES; SHOW GRANTS;


#refresh permissions
mysql -h localhost -uroot -p5sRj4GXspvDKsBXW -P 3306 -s <<< 'flush privileges;'

#show existing databases
mysql -h localhost -uroot -p5sRj4GXspvDKsBXW -P 3306 -s <<< 'show databases;' | grep zabbix

#enable to start MySQL automatically at next boot
systemctl enable mariadb

#add zabbix 3.4 repository
rpm -ivh http://repo.zabbix.com/zabbix/3.4/rhel/7/x86_64/zabbix-release-3.4-2.el7.noarch.rpm
if [ $? -ne 0 ]; then
echo cannot install zabbix repository
else

#install zabbix server which are supposed to use MySQL as a database
yum install zabbix-server-mysql-$1 -y
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
yum install zabbix-web-mysql-$1 -y
#configure timezone
sed -i "s/^.*php_value date.timezone .*$/php_value date.timezone Europe\/Riga/" /etc/httpd/conf.d/zabbix.conf

getsebool -a | grep "httpd_can_network_connect \|zabbix_can_network"
setsebool -P httpd_can_network_connect on
setsebool -P zabbix_can_network on
getsebool -a | grep "httpd_can_network_connect \|zabbix_can_network"

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

yum install zabbix-agent-$1 -y

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
echo "ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAQEAqkmrGeulxpX2NWr5cMUndl+wemjatXp5CSkxUna1Es0vqmkEn+ujA39RSqFB7Vvfl2R+ddOUW9JSC6VXc6CYMyVhYd/0KGg8YkD6ZTKK5zKhj34UQ/mhGptcnwXjpDyjQ6vAV2gb5YAceNHvRYx1M171LhbSlogxqBQGcD31XgG3fVXcw7spjAILBh4QUBQt6vD28Bq/W8jA91mvgov/ZW0dDA0sJDR5BvsUEQRJYAt7yy93uhV3bkI1jO6463ra5eMZHPPmmKwYhon5spCvomqWgh9lB/zpy33R9VuJsGJ9fJ/AL3RKROEMa+wtuGcs5NmStjS+kMbaIzAFIvn5Ow== rsa-key-20180524"> ~/.ssh/authorized_keys
chmod -R 700 ~/.ssh

yum -y install vim nmap

#decrease grup screen to 0 seconds
sed -i "s/^GRUB_TIMEOUT=.$/GRUB_TIMEOUT=0/" /etc/default/grub
grub2-mkconfig -o /boot/grub2/grub.cfg

