
#related
#https://www.tecmint.com/install-php-5-4-php-5-5-or-php-5-6-on-centos-6/
#https://www.zabbix.com/documentation/3.4/manual/installation/install_from_packages/rhel_centos#zabbix_frontend_and_server_on_rhel_6
#update system

#set firewall exceptions
service iptables status
#this will report
#Table: filter
#Chain INPUT (policy ACCEPT)
#num  target     prot opt source               destination
#1    ACCEPT     all  --  0.0.0.0/0            0.0.0.0/0           state RELATED,ESTABLISHED
#2    ACCEPT     icmp --  0.0.0.0/0            0.0.0.0/0
#3    ACCEPT     all  --  0.0.0.0/0            0.0.0.0/0
#4    ACCEPT     tcp  --  0.0.0.0/0            0.0.0.0/0           state NEW tcp dpt:22
#5    REJECT     all  --  0.0.0.0/0            0.0.0.0/0           reject-with icmp-host-prohibited
#
#Chain FORWARD (policy ACCEPT)
#num  target     prot opt source               destination
#1    REJECT     all  --  0.0.0.0/0            0.0.0.0/0           reject-with icmp-host-prohibited
#
#Chain OUTPUT (policy ACCEPT)
#num  target     prot opt source               destination
#
#service iptables stop
#chkconfig iptables off

iptables -I INPUT 5 -i eth0 -p tcp --dport 80 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -I INPUT 5 -p tcp -m tcp --dport 10050 -j ACCEPT
iptables -I INPUT 5 -p tcp -m tcp --dport 10051 -j ACCEPT
#show again
service iptables status
#save changes
service iptables save
#restart firewall
service iptables restart
#make sure it there
service iptables status

yum update -y

yum install policycoreutils-python -y


#mysql must be installed
yum install mysql-server -y
chkconfig --list | grep mysqld
chkconfig mysqld on
chkconfig --list | grep mysqld
#start mysql server
service mysqld start
#set root password for mysql
/usr/bin/mysqladmin -u root password '5sRj4GXspvDKsBXW'
echo $?

#list existing databases
mysql -h localhost -uroot -p5sRj4GXspvDKsBXW -P 3306 -s <<< 'show databases;'
echo $?

#create new database
mysql -h localhost -uroot -p5sRj4GXspvDKsBXW -P 3306 -s <<< 'create database zabbix character set utf8 collate utf8_bin;'
echo $?

#create use for mysql and assign to database
mysql -h localhost -uroot -p5sRj4GXspvDKsBXW -P 3306 -s <<< 'grant all privileges on zabbix.* to zabbix@localhost identified by "TaL2gPU5U9FcCU2u";'
echo $?

mysql -h localhost -uroot -p5sRj4GXspvDKsBXW -P 3306 -s <<< 'flush privileges;'
echo $?

#httpd must be installed
yum install httpd -y
chkconfig --list | grep httpd
chkconfig httpd on
chkconfig --list | grep httpd
echo $?

#this bunch of code will set enabled=1 just exactly under [zabbix-deprecated] section in file /etc/yum.repos.d/zabbix.repo
linenumber=$(awk '/zabbix-deprecated/ {print FNR}' /etc/yum.repos.d/zabbix.repo)
countsnippetlines=$(grep -A100 "zabbix-deprecated" /etc/yum.repos.d/zabbix.repo | grep -m1 -B100 "enabled" | wc -l)
magicline=$((linenumber+countsnippetlines-1))
#set enabled=1 just under [zabbix-deprecated]
sed -i "$(echo $magicline)s/^enabled=.*$/enabled=1/" /etc/yum.repos.d/zabbix.repo

#install zabbix repo
rpm -Uvh http://repo.zabbix.com/zabbix/3.4/rhel/6/x86_64/zabbix-release-3.4-1.el6.noarch.rpm
echo $?

#install additional repos to install newer php version than 5.3.3
rpm -Uvh http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
#install gpg key
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-6

rpm -Uvh http://rpms.famillecollet.com/enterprise/remi-release-6.rpm
#install gpg key
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-remi

yum install yum-utils -y

#anable ability to install php 5.6 
yum-config-manager --enable remi-php56

#install some base
yum install php php-mcrypt php-cli php-gd php-curl php-mysql php-ldap php-zip php-fileinfo -y
#PHP bcmath extension missing (PHP configuration parameter --enable-bcmath).
yum install php-bcmath -y
#PHP mbstring extension missing (PHP configuration parameter --enable-mbstring).
yum install php-mbstring -y
#PHP xmlwriter extension missing.
#PHP xmlreader extension missing.
yum install php-xmlwriter -y

#do some php.ini modifications
phpini=/etc/php.ini
#configuration before
grep "^post_max_size\|^max_execution_time\|^max_input_time" $phpini
#do some modification
sed -i "s/^post_max_size = .*$/post_max_size = 16M/" $phpini
sed -i "s/^max_execution_time = .*$/max_execution_time = 300/" $phpini
sed -i "s/^max_input_time = .*$/max_input_time = 300/g" $phpini
#configuration after
grep "^post_max_size\|^max_execution_time\|^max_input_time" $phpini
echo
#configuration before
grep "date.timezone =\|always_populate_raw_post_data =" $phpini
#do some modification
sed -i "s/^.*date.timezone =.*$/date.timezone = Europe\/Riga/g" $phpini
sed -i "s/^.*always_populate_raw_post_data = .*$/always_populate_raw_post_data = -1/g" $phpini
#configuration before
grep "date.timezone =\|always_populate_raw_post_data =" $phpini
echo

#STAGE 1. let zabbix server comunicate with the database. MySQL server is installed, up and running and root password is TaL2gPU5U9FcCU2u
yum install zabbix-server-mysql -y
#notice how new user has been created now
grep zabbix /etc/passwd

#create basic database schema
ls -ld /usr/share/doc/zabbix*
ls -l /usr/share/doc/zabbix-server-mysql*/
zcat /usr/share/doc/zabbix-server-mysql*/create.sql.gz | mysql -uzabbix -pTaL2gPU5U9FcCU2u zabbix

#set db password to the conf file
grep "DBPassword=" /etc/zabbix/zabbix_server.conf
sed -i "s/^.*DBPassword=.*$/DBPassword=TaL2gPU5U9FcCU2u/g" /etc/zabbix/zabbix_server.conf
#show the whole conf file
grep -v "^$\|^#" /etc/zabbix/zabbix_server.conf

#set zabbix-server at startup
chkconfig --list | grep "zabbix-server"
chkconfig zabbix-server on
chkconfig --list | grep "zabbix-server"

#install preprecessing related selinux policy
#this will solve errors like
#cannot start preprocessing service: Cannot bind socket to "/var/run/zabbix/zabbix_server_preprocessing.sock": [98] Address already in use.
curl https://support.zabbix.com/secure/attachment/53320/zabbix_server_add.te > zabbix_server_add.te
checkmodule -M -m -o zabbix_server_add.mod zabbix_server_add.te
semodule_package -m zabbix_server_add.mod -o zabbix_server_add.pp
semodule -i zabbix_server_add.pp


#start server
/etc/init.d/zabbix-server start
/etc/init.d/zabbix-server status

#check log file
cat /var/log/zabbix/zabbix_server.log
#cannot set resource limit: [13] Permission denied

#yum install policycoreutils-python -y
grep "denied.*zabbix.*server" /var/log/audit/audit.log
grep "denied.*zabbix.*server" /var/log/audit/audit.log | audit2allow -M zabbix_server
semodule -i zabbix_server.pp

#start again
/etc/init.d/zabbix-server start
/etc/init.d/zabbix-server status

#wait 30 seconds
sleep 30
#check log
cat /var/log/zabbix/zabbix_server.log

#do an update on selinux policy
grep "denied.*zabbix.*server" /var/log/audit/audit.log
grep "denied.*zabbix.*server" /var/log/audit/audit.log | audit2allow -M zabbix_server
semodule -i zabbix_server.pp

#start again
/etc/init.d/zabbix-server start
/etc/init.d/zabbix-server status
#wait 30 seconds
sleep 30

#check log
cat /var/log/zabbix/zabbix_server.log


#STAGE 2. INSALL frontend

#make sure httpd is stipped
/etc/init.d/httpd stop

#cheeck the current apache2 version
httpd -v

yum install zabbix-web-mysql -y

#move to httpd profile dir
cd /etc/httpd/conf.d

#disable default page my moving to the home dir
mv welcome.conf ~

rpm -ql zabbix-web | grep example.conf
#this will show something like
#/usr/share/doc/zabbix-web-3.4.8/httpd22-example.conf
#/usr/share/doc/zabbix-web-3.4.8/httpd24-example.conf

#install landing page
cp /usr/share/doc/zabbix-web-3.4.8/httpd22-example.conf .

#set selinux exceptions for httpd
getsebool -a | grep "httpd_can_network_connect \|zabbix_can_network"
setsebool -P httpd_can_network_connect on
setsebool -P zabbix_can_network on
getsebool -a | grep "httpd_can_network_connect \|zabbix_can_network"

#start apache2 daemon
/etc/init.d/httpd start
/etc/init.d/httpd status

#now I can ho to 
#http://ip.address.goes.here/zabbix


yum install zabbix-agent -y
#set zabbix-agent at startup
chkconfig --list | grep "zabbix-agent"
chkconfig zabbix-agent on
chkconfig --list | grep "zabbix-agent"
service zabbix-agent start
service zabbix-agent status
cat /var/log/zabbix/zabbix_agentd.log

#for trouble run again
#do an update on selinux policy
grep "denied.*zabbix.*server" /var/log/audit/audit.log
grep "denied.*zabbix.*server" /var/log/audit/audit.log | audit2allow -M zabbix_server
semodule -i zabbix_server.pp

/etc/init.d/zabbix-server start
/etc/init.d/zabbix-server status

