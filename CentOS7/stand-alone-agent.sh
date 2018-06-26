mkdir ~/agent34
cd ~/agent34
wget http://repo.zabbix.com/zabbix/3.4/rhel/7/x86_64/zabbix-agent-3.4.11-1.el7.x86_64.rpm
rpm2cpio zabbix-agent-3.4.11-1.el7.x86_64.rpm | cpio -idmv
cd ~/agent34/usr/sbin
./zabbix_agentd -c ~/zabbix_agentd.conf -f

