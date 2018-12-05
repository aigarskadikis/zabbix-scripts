#!/bin/bash

#this is tested and works together with fresh CentOS-7-x86_64-Minimal-1708.iso
#cd && curl https://raw.githubusercontent.com/catonrug/zabbix-scripts/master/CentOS/custom-server-4.0-LTS-postgresql.sh > install.sh && chmod +x install.sh && time ./install.sh

#update system
yum update -y

#install SELinux debuging utils
yum -y install policycoreutils-python bzip2 nmap vim 

yum -y install postgresql && yum -y install postgresql-server

# disable SELinux
sed -i "s/^SELINUX=.*$/SELINUX=disabled/" /etc/selinux/config
setenforce 0

/usr/bin/postgresql-setup initdb

systemctl enable postgresql
systemctl start postgresql

rpm -ivh http://repo.zabbix.com/zabbix/4.0/rhel/7/x86_64/zabbix-release-4.0-1.el7.noarch.rpm

yum -y install zabbix-server-pgsql zabbix-web-pgsql zabbix-agent

# sudo -u postgres dropdb zabbix
# sudo -u postgres dropuser zabbix

sudo -u postgres bash -c "psql -c \"CREATE USER zabbix WITH PASSWORD 'zabbix';\""
# sudo -u postgres createuser --pwprompt zabbix

sudo -u postgres createdb -O zabbix zabbix

zcat /usr/share/doc/zabbix-server-pgsql*/create.sql.gz | sudo -u zabbix psql zabbix

#define server conf file
server=/etc/zabbix/zabbix_server.conf

grep "^DBPassword=" $server
if [ $? -eq 0 ]; then
sed -i "s/^DBPassword=.*/DBPassword=zabbix/" $server #modifies already customized setting
else
ln=$(grep -n "DBPassword=" $server | egrep -o "^[0-9]+"); ln=$((ln+1)) #calculate the the line number after default setting
sed -i "`echo $ln`iDBPassword=zabbix" $server #adds new line
fi

grep "^DBHost=" $server
if [ $? -eq 0 ]; then
sed -i "s/^DBHost=.*/DBHost=/" $server #modifies already customized setting
else
ln=$(grep -n "DBHost=" $server | egrep -o "^[0-9]+"); ln=$((ln+1)) #calculate the the line number after default setting
sed -i "`echo $ln`iDBHost=" $server #adds new line
fi


sed -i "s/^.*php_value date.timezone .*$/php_value date.timezone Europe\/Riga/" /etc/httpd/conf.d/zabbix.conf

cp /var/lib/pgsql/data/{pg_hba.conf,pg_hba.conf.original}
cat <<'EOF'> /var/lib/pgsql/data/pg_hba.conf
# "local" is for Unix domain socket connections only
local   all             all                                     md5
# IPv4 local connections:
host    all             all             127.0.0.1/32            md5
# IPv6 local connections:
host    all             all             ::1/128                 md5
EOF

systemctl restart zabbix-server zabbix-agent postgresql httpd && systemctl enable zabbix-server zabbix-agent httpd
