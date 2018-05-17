
#update repos
yum update -yum

#install zabbix repo
rpm -i http://repo.zabbix.com/zabbix/3.0/rhel/7/x86_64/zabbix-release-3.0-1.el7.noarch.rpm

#install necesary packages
#mariadb as backend server
#zabbix_get emulate zabbix servers poller process. emulates zabbix server. the main advantage it to poll key from remote host.
yum install zabbix-server-mysql zabbix-web-mysql mariadb-server zabbix-agent telnet nmap vim zabbix-sender zabbix-get -y
#mariadsb can be installed from www.mariadb.com

#start mysql server
systemctl start mariadb

#enable mysql server at startup
systemctl enable mariadb

#change the root password
mysql_secure_installation

#NOTE: RUNNING ALL PARTS OF THIS SCRIPT IS RECOMMENDED FOR ALL MariaDB
#      SERVERS IN PRODUCTION USE!  PLEASE READ EACH STEP CAREFULLY!
#
#In order to log into MariaDB to secure it, we'll need the current
#password for the root user.  If you've just installed MariaDB, and
#you haven't set the root password yet, the password will be blank,
#so you should just press enter here.
#
#Enter current password for root (enter for none):
#ERROR 1045 (28000): Access denied for user 'root'@'localhost' (using password: YES)
#Enter current password for root (enter for none):
#Aborting!
#
#Cleaning up...
#[root@student-01 ~]# mysql_secure_installation
#
#NOTE: RUNNING ALL PARTS OF THIS SCRIPT IS RECOMMENDED FOR ALL MariaDB
#      SERVERS IN PRODUCTION USE!  PLEASE READ EACH STEP CAREFULLY!
#
#In order to log into MariaDB to secure it, we'll need the current
#password for the root user.  If you've just installed MariaDB, and
#you haven't set the root password yet, the password will be blank,
#so you should just press enter here.
#
#Enter current password for root (enter for none):
#OK, successfully used password, moving on...
#
#Setting the root password ensures that nobody can log into the MariaDB
#root user without the proper authorisation.
#
#Set root password? [Y/n] Y
#New password:
#Re-enter new password:
#Password updated successfully!
#Reloading privilege tables..
# ... Success!
#
#
#By default, a MariaDB installation has an anonymous user, allowing anyone
#to log into MariaDB without having to have a user account created for
#them.  This is intended only for testing, and to make the installation
#go a bit smoother.  You should remove them before moving into a
#production environment.
#
#Remove anonymous users? [Y/n] y
# ... Success!
#
#Normally, root should only be allowed to connect from 'localhost'.  This
#ensures that someone cannot guess at the root password from the network.
#
#Disallow root login remotely? [Y/n] y
# ... Success!
#
#By default, MariaDB comes with a database named 'test' that anyone can
#access.  This is also intended only for testing, and should be removed
#before moving into a production environment.
#
#Remove test database and access to it? [Y/n] y
# - Dropping test database...
# ... Success!
# - Removing privileges on test database...
# ... Success!
#
#Reloading the privilege tables will ensure that all changes made so far
#will take effect immediately.
#
#Reload privilege tables now? [Y/n] y
# ... Success!
#
#Cleaning up...
#
#All done!  If you've completed all of the above steps, your MariaDB
#installation should now be secure.
#
#Thanks for using MariaDB!

#not recommed to use this way. Postgresql does not allow to use this.
mysql -pzabbix31415

#enter mysql mode
mysql -p

create database zabbix character set utf8 collate utf8_bin;

grant all privileges on zabbix.* to zabbix@localhost identified by 'zabbix';

#substitute user. seperate user for frontend and backend;

show grants;

\q

zcat /usr/share/doc/zabbix-server-mysql-3.0.17/create.sql.gz | mysql -uzabbix -p zabbix
#enter password 'zabbix'

#add the password at the end of file
echo "DBPassword=zabbix" >> /etc/zabbix/zabbix_server.conf

#start the server and check for log
systemctl start zabbix-server && tailf /var/log/zabbix/zabbix_server.log
#first 4 digits is pid number. later we can degub the process with 'ss' utility

#scrollable way to look on log file
less /var/log/zabbix/zabbix_server.log

#if the configuration has unsupported atributes
zabbix_server

systemctl start httpd

ip a

firewall-cmd --permanent --zone=public --add-port=80/tcp #for http
firewall-cmd --permanent --zone=public --add-port=10050/tcp #passive checks. item polling
firewall-cmd --permanent --zone=public --add-port=10051/tcp #active checks. item receiving
firewall-cmd --reload
firewall-cmd --list-all

#firewall-cmd --permanent --add-service=http

#uncoment time zone
vim /etc/httpd/conf.d/zabbix.conf

systemctl restart httpd


cat /etc/zabbix/web/zabbix.conf.php

#install zabbix agent
systemctl start zabbix-agent

#enable agent and httpd at startup
systemctl enable zabbix-agent httpd

