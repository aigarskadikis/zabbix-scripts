

# stop back-end and front-end
systemctl stop zabbix-server httpd

# disable at startup
systemctl disable zabbix-server httpd


# list biggest tables
SELECT table_name, table_rows, data_length, index_length, round(((data_length + index_length) / 1024 / 1024 ),2) "Size in MB" FROM information_schema.tables WHERE table_schema = "zabbix" order by round(((data_length + index_length) / 1024 / 1024 ),2) DESC LIMIT 20;


# rename existing table_name
rename table history_text to history_text_old;

# create a blank table like the old one
create table history_text like history_text_old;

# exit mysql client
exit

# remove old repo
yum -y remove zabbix-release

# install 4.0 repo
rpm -ivh http://repo.zabbix.com/zabbix/4.0/rhel/7/x86_64/zabbix-release-4.0-1.el7.noarch.rpm

# clean yum cache
yum clean all && rm -rf /var/cache/yum && yum -y makecache fast

# update zabbix packages
yum -y update zabbix-*

systemctl start zabbix-server

tail -50f /var/log/zabbix/zabbix_server.log

# see the difference of tables
show create table history_text_old\G;
show create table history_text\G;



insert into history_text select itemid, clock, value, ns from history_text_old;






