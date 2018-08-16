
# ip: 10.0.2.81

# move to super user
sudo su

# install vagrant ssh key
echo "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA6NF8iallvQVp22WDkTkyrtvp9eWW6A8YVr+kz4TjGYe7gHzIw+niNltGEFHzD8+v1I2YJ6oXevct1YeS0o9HZyN1Q9qgCgzUFtdOKLv6IedplqoPkcmF0aYet2PkEDo3MlTBckFXPITAMzF8dJSIFo9D8HfdOV0IAdx4O7PtixWKn5y2hMNG0zQPyUecp4pzC6kivAIhyfHilFR61RGL+GPXQ2MWZWFYbAGjyiYJnAmCP3NOTd0jMZEnDkbUvxhMmBYSdETk1rRgm+R4LOzFUGaHqHDLKLX+FIPKcF96hrucXzcWyLbIbEgE98OHlnVYCzRdK8jlqm8tehUc9c9WhQ== imported-openssh-key" > ~/.ssh/authorized_keys
chmod -R 600 ~/.ssh/authorized_keys


# observe the centos version
rpm --query centos-release

# disable SELinux on the fly and after reboot
setenforce 0 && sed -i "s/^SELINUX=.*$/SELINUX=disabled/" /etc/selinux/config && getenforce

# status of firewalld
systemctl status firewalld

# disable selinux at next bootup

# update system
yum -y update && yum -y upgrade

# install time daemon
yum -y install ntp && systemctl enable ntpd && systemctl start ntpd

# set time zone
sudo cp /usr/share/zoneinfo/Etc/GMT-3 /etc/localtime
date 

# setup some conveniences
yum -y install vim

# add MariaDB repo from http://downloads.mariadb.org/mariadb/repositories/
echo "IyBNYXJpYURCIDEwLjIgQ2VudE9TIHJlcG9zaXRvcnkgbGlzdCAtIGNyZWF0ZWQgMjAxOC0wOC0xMyAwNjozOSBVVEMKIyBodHRwOi8vZG93bmxvYWRzLm1hcmlhZGIub3JnL21hcmlhZGIvcmVwb3NpdG9yaWVzLwpbbWFyaWFkYl0KbmFtZSA9IE1hcmlhREIKYmFzZXVybCA9IGh0dHA6Ly95dW0ubWFyaWFkYi5vcmcvMTAuMi9jZW50b3M3LWFtZDY0CmdwZ2tleT1odHRwczovL3l1bS5tYXJpYWRiLm9yZy9SUE0tR1BHLUtFWS1NYXJpYURCCmdwZ2NoZWNrPTEK" | base64 --decode > /etc/yum.repos.d/MariaDB.repo
cat /etc/yum.repos.d/MariaDB.repo


# generate cache
yum makecache

# install mariadb server
yum -y install MariaDB-server MariaDB-client

# During installation process MariaDB package will configure initial database and create redo log files with default file size. Remove these files: 
rm -rf /var/lib/mysql/ib_logfile*

vim /etc/my.cnf.d/server.cnf
# make sure [mysqld] section contains:
log-bin
server_id = 1
log-basename=master1



systemctl restart mariadb
systemctl status mariadb
systemctl enable mariadb

# open mysql
mysql

show variables like 'server_id';
show slave status\G;

# check the ip address of host
system ip a

# [test the accesss on node2]
mysql -ureplicator -preplicator -h10.0.2.81

# [run on node1. set the permissions]
GRANT REPLICATION SLAVE ON *.* TO 'replicator'@'10.0.2.82' identified by 'replicator'; FLUSH PRIVILEGES;

# [test if node2 can access node1]
mysql -ureplicator -preplicator -h10.0.2.81

# [test if node1 can access node2
mysql -ureplicator -preplicator -h10.0.2.82

# [run on node2]
GRANT REPLICATION SLAVE ON *.* TO 'replicator'@'10.0.2.81' identified by 'replicator'; FLUSH PRIVILEGES;


FLUSH TABLES WITH READ LOCK;

# create a dump. note we are using root account without password:
cd
mysqldump --master-data --gtid --all-databases > backup.sql

# deliver the backup to second node
scp ~/backup.sql root@10.0.2.82:~

restoru

otrai datubāzei uzlike māsteru

pirmai datubāsei uzliek māster

# [run on node1]
SHOW SLAVE STATUS;
STOP SLAVE;
CHANGE MASTER TO master_host="10.0.2.82", master_port=3306, master_user="replicator", master_password="replicator", master_use_gtid=current_pos;
START SLAVE;
SHOW SLAVE STATUS\G;

# Got fatal error 1236 from master when reading data from binary log: 'Binary log is not open'
# Slave_SQL_Running_State: Slave has read all relay log; waiting for the slave I/O thread to update it

# [run on node2]
SHOW SLAVE STATUS;
STOP SLAVE;
CHANGE MASTER TO master_host="10.0.2.81", master_port=3306, master_user="replicator", master_password="replicator", master_use_gtid=current_pos;
START SLAVE;
SHOW SLAVE STATUS\G;






# test if the replication works
create database zabbix character set utf8 collate utf8_bin;
show databases;


UNLOCK TABLES;
# stop slave;

# reset slave
# reset master
