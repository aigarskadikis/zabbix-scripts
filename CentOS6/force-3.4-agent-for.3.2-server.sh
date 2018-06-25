#remove existing agent
yum remove zabbix-agent

#if wget is not installed
yum install wget

#look for desired version in http://repo.zabbix.com/zabbix/3.4/rhel/6/x86_64/

#go to home
cd

#download package
wget http://repo.zabbix.com/zabbix/3.4/rhel/6/x86_64/zabbix-agent-3.4.11-1.el6.x86_64.rpm

rpm -iv zabbix-agent-3.4.11-1.el6.x86_64.rpm

#to manually install zabbix-agent 