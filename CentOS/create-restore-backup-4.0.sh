systemctl stop zabbix-server httpd zabbix-agent
ps aux|grep [z]abbix

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
--ignore-table=zabbix.node_cksum zabbix | gzip  > /root/conf.only.gz

# backup everything, just in case
sudo mysqldump zabbix | gzip > /root/zbx.all.gz
mysql <<< 'drop database zabbix;'
mysql <<< 'create database zabbix character set utf8 collate utf8_bin;'
mysql <<< 'grant all privileges on zabbix.* to "zabbix"@"localhost" identified by "zabbix";'
cd /usr/share/doc/zabbix-server-mysql*/
ls -lh
zcat create.sql.gz | mysql zabbix

cd && zcat conf.only.gz | mysql zabbix
systemctl start zabbix-server httpd zabbix-agent



