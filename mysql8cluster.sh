#!/bin/bash


sudo dd if=/dev/zero of=/myswap1 bs=1M count=1024 && sudo chown root:root /myswap1 && sudo chmod 0600 /myswap1 && sudo mkswap /myswap1 && sudo swapon /myswap1 && free -m

sudo dd if=/dev/zero of=/myswap2 bs=1M count=1024 && sudo chown root:root /myswap2 && sudo chmod 0600 /myswap2 && sudo mkswap /myswap2 && sudo swapon /myswap2 && free -m

sudo dd if=/dev/zero of=/myswap3 bs=1M count=1024 && sudo chown root:root /myswap3 && sudo chmod 0600 /myswap3 && sudo mkswap /myswap3 && sudo swapon /myswap3 && free -m

sudo dd if=/dev/zero of=/myswap4 bs=1M count=1024 && sudo chown root:root /myswap4 && sudo chmod 0600 /myswap4 && sudo mkswap /myswap4 && sudo swapon /myswap4 && free -m

echo 1 | sudo tee /proc/sys/vm/overcommit_memory

setenforce 0


# install repository
sudo yum -y install https://dev.mysql.com/get/mysql80-community-release-el7-3.noarch.rpm


sudo yum makecache fast
# sudo yum -y update

# install conveniences
sudo yum -y install vim

# install time daemon
sudo yum -y install ntp

sudo systemctl stop ntpd
sudo ntpd -gq
sudo systemctl start ntpd

sudo systemctl enable ntpd

timedatectl set-timezone "Europe/Riga"

date

sudo yum -y install mysql-community-client mysql-community-server

# add to [mysqld] section
cat << EOF >> /etc/my.cnf

enforce_gtid_consistency = on
gtid_mode = on
log_slave_updates = on
log_bin = on
binlog_format = row
binlog_checksum = none
sync_binlog = 1
master_info_repository = table
relay_log_info_repository = table
transaction_write_set_extraction = XXHASH64
disabled_storage_engines = "MyISAM,BLACKHOLE,FEDERATED,ARCHIVE,MEMORY"
default-authentication-plugin=mysql_native_password
server_id = $(hostname -s | grep -Eo "[0-9]+" | sed "s|$|0|")
EOF

sudo systemctl start mysqld
sudo systemctl enable mysqld

# change password. do not use '!' in password
grep "temporary password" /var/log/mysqld.log | sed "s|^.*localhost:.||" | xargs -i echo "/usr/bin/mysqladmin -u root password 'z4bbi#SIA' -p'{}'" | sudo bash

# set the same password as in previous step
cat << 'EOF' > ~/.my.cnf
[client]
user=root
password='z4bbi#SIA'
EOF


# never point to 127.0.0.1 while working with nodes
sed -i "s|^.*$(hostname -s).*$||" /etc/hosts

# add additional records
echo '
10.133.80.228 mysql1
10.133.253.44 mysql2
10.133.253.45 mysql3
' | tee -a /etc/hosts

# on all nodes
cat << EOF >> /etc/my.cnf

report_host = $(hostname -s)
group_replication_ip_whitelist = mysql1,mysql2,mysql3
plugin_load_add = group_replication.so
group_replication_start_on_boot = on
group_replication_single_primary_mode = on

EOF
cat /etc/my.cnf

# user to administer cluster
mysql -e '
CREATE USER "cluster_admin"@"%" IDENTIFIED BY "z4bbi#SIA";
GRANT ALL PRIVILEGES ON *.* TO "cluster_admin"@"%" WITH GRANT OPTION;
'

sudo systemctl stop mysqld && sudo systemctl start mysqld


sudo yum -y install mysql-shell



# on first kickstart node
mysql -e '
CREATE USER "zabbix"@"%" IDENTIFIED BY "z4bbi#SIA";
ALTER USER "zabbix"@"%" IDENTIFIED WITH mysql_native_password BY "z4bbi#SIA";
CREATE DATABASE zabbix CHARACTER SET utf8 COLLATE utf8_bin;
GRANT SELECT, UPDATE, DELETE, INSERT, CREATE, DROP, ALTER, INDEX, REFERENCES ON zabbix.* TO "zabbix"@"%";
FLUSH PRIVILEGES;
'

curl -kLs "https://cdn.zabbix.com/zabbix/sources/stable/5.0/zabbix-5.0.3.tar.gz" -o zabbix-source.tar.gz
ls -lh
tar -xzf zabbix-source.tar.gz 

cd ~/zabbix-5.0.3/database/mysql
cat schema.sql images.sql data.sql | mysql zabbix

mysql -e '
ALTER TABLE `zabbix`.`history` ADD `id` bigint PRIMARY KEY AUTO_INCREMENT;
ALTER TABLE `zabbix`.`history_uint` ADD `id` bigint PRIMARY KEY AUTO_INCREMENT;
ALTER TABLE `zabbix`.`history_str` ADD `id` bigint PRIMARY KEY AUTO_INCREMENT;
ALTER TABLE `zabbix`.`history_log` ADD `id` bigint PRIMARY KEY AUTO_INCREMENT;
ALTER TABLE `zabbix`.`history_text` ADD `id` bigint PRIMARY KEY AUTO_INCREMENT;
ALTER TABLE `zabbix`.`dbversion` ADD `id` bigint PRIMARY KEY AUTO_INCREMENT;
'

mysqlsh /c cluster_admin@mysql1:3306

var i1='cluster_admin@mysql1:3306',i2='cluster_admin@mysql2:3306',i3='cluster_admin@mysql3:3306';

dba.checkInstanceConfiguration(i1);
# z4bbi#SIA
dba.checkInstanceConfiguration(i2);
dba.checkInstanceConfiguration(i3);


var cluster=dba.createCluster('zabbix_cluster',{
memberWeight: 50,
memberSslMode: "REQUIRED",
ipWhitelist: "mysql1, mysql2, mysql3",
localAddress: "mysql1"
});

