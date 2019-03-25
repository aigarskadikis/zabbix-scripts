# take a note how many proxies we will are having

# stop back-end and front-end and disable at startup
systemctl stop zabbix-server httpd zabbix-agent && systemctl disable zabbix-server httpd zabbix-agent

mysql zabbix

# list biggest tables
SELECT table_name, table_rows, data_length, index_length, round(((data_length + index_length) / 1024 / 1024 ),2) "Size in MB" FROM information_schema.tables WHERE table_schema = "zabbix" order by round(((data_length + index_length) / 1024 / 1024 ),2) DESC LIMIT 20;

# rename existing table_name
rename table history_text to history_text_old;

# create a blank table like the old one
create table history_text like history_text_old;

# exit mysql client
exit

# on old server the backup has been made and is placed on /root/zabbix.full.gz


cd
sudo mysqldump \
--flush-logs \
--single-transaction \
--create-options \
--ignore-table=zabbix.acknowledges \
--ignore-table=zabbix.alerts \
--ignore-table=zabbix.auditlog \
--ignore-table=zabbix.auditlog_details \
--ignore-table=zabbix.escalations \
--ignore-table=zabbix.events \
--ignore-table=zabbix.history \
--ignore-table=zabbix.history_log \
--ignore-table=zabbix.history_str \
--ignore-table=zabbix.history_str_sync \
--ignore-table=zabbix.history_sync \
--ignore-table=zabbix.history_text \
--ignore-table=zabbix.history_uint \
--ignore-table=zabbix.history_uint_sync \
--ignore-table=zabbix.profiles \
--ignore-table=zabbix.service_alarms \
--ignore-table=zabbix.sessions \
--ignore-table=zabbix.trends \
--ignore-table=zabbix.trends_uint \
--ignore-table=zabbix.user_history \
--ignore-table=zabbix.node_cksum zabbix | gzip > conf.zbx.gz

# on new server
yum -y install mariadb-server
systemctl start mariadb && systemctl enable mariadb
mysql <<< 'show databases;' | grep zabbix

rpm -ivh http://repo.zabbix.com/zabbix/2.2/rhel/7/x86_64/zabbix-release-2.2-1.el7.noarch.rpm
yum -y install zabbix-server-mysql

# optional drop old database
# mysql <<< 'drop database zabbix;'

# create database. utf8 is required to go wordwide and support ANY character. Collate is required to create case sensitive hosts.
mysql <<< 'create database zabbix character set utf8 collate utf8_bin;'

# create user zabbix and allow user to connect to the database with only from localhost
mysql <<< 'grant all privileges on zabbix.* to "zabbix"@"localhost" identified by "zabbix";'
mysql <<< 'show databases;' | grep zabbix

cd /usr/share/doc/zabbix-server-mysql-*/create
ls -lh
cat schema.sql | mysql zabbix
cat images.sql | mysql zabbix
cat data.sql | mysql zabbix
# check if some tables is there
mysql zabbix <<< 'show tables;'

# partitioning step must be implemented here if the instance is huge


# move back to home to override from backup
cd
zcat conf.zbx.gz | mysql zabbix

# make sure the old config is there
cd && cat zabbix_server.conf > /etc/zabbix/zabbix_server.conf
getenforce
systemctl start zabbix-server
tail -20 /var/log/zabbix/zabbix_server.log
systemctl stop zabbix-server
tail -1 /var/log/zabbix/zabbix_server.log
# the old version must be in log for the last time

# remove old repo
yum -y remove zabbix-release

# install 4.0 repo
rpm -ivh http://repo.zabbix.com/zabbix/4.0/rhel/7/x86_64/zabbix-release-4.0-1.el7.noarch.rpm

# clean yum cache
yum clean all && rm -rf /var/cache/yum && yum -y makecache fast

# check if nothing is running
ps aux|grep [z]abbix

# update zabbix package "zabbix-server-mysql"
yum -y update zabbix-server-mysql-*

# see the last lines at log file
tail -20 /var/log/zabbix/zabbix_server.log
# it should say the old version at the end

# check SELinux status
getenforce

systemctl start zabbix-server && tail -50f /var/log/zabbix/zabbix_server.log

# there should be message in the middle
# Action "Report problems to Zabbix administrators" condition "Trigger value = PROBLEM" will be removed during database upgrade: this type of condition is not supported anymore

# see the difference of tables
show create table history_text_old\G;
show create table history_text\G;

# if everything is cool the start frontend
systemctl start httpd
systemctl start zabbix-agent

# enable everything at startup
systemctl enable zabbix-server httpd zabbix-agent

insert into history_text select itemid, clock, value, ns from history_text_old;


