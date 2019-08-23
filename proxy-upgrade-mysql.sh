
# yum install -y zabbix-proxy-mysql zabbix-agent
# rpm -ivh http://repo.zabbix.com/zabbix/4.0/rhel/7/x86_64/zabbix-release-4.0-1.el7.noarch.rpm

systemctl stop zabbix-proxy zabbix-agent
yum -y remove zabbix-release
yum clean all
rm -rf /var/cache/yum
rpm -ivh https://repo.zabbix.com/zabbix/4.2/rhel/7/x86_64/zabbix-release-4.2-2.el7.noarch.rpm
yum makecache fast
yum -y update zabbix-*
mysql <<< 'drop database zabbix_proxy;'
mysql <<< 'create database zabbix_proxy character set utf8 collate utf8_bin;'
mysql <<< 'grant all privileges on zabbix_proxy.* to zabbix@localhost identified by "zabbix";'
zcat /usr/share/doc/zabbix-proxy-mysql-4.2*/schema.sql.gz | mysql -u'zabbix' -p'zabbix' zabbix_proxy
systemctl start zabbix-proxy zabbix-agent
systemctl enable zabbix-proxy zabbix-agent
grep " Zabbix Proxy " /var/log/zabbix/zabbix_proxy.log
cat /var/log/zabbix/zabbix_proxy.log


