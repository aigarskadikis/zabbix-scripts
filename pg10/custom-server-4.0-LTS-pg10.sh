#!/bin/bash

#cd && curl https://raw.githubusercontent.com/catonrug/zabbix-scripts/master/pg10/custom-server-4.0-LTS-pg10.sh > install.sh && chmod +x install.sh && time ./install.sh 4.0.3

#open 80 and 443 into firewall
systemctl enable firewalld
systemctl start firewalld

firewall-cmd --permanent --add-service=http
firewall-cmd --permanent --add-service=https
firewall-cmd --add-port=162/udp --permanent # to recieve zabbix traps
firewall-cmd --add-port=10050/tcp --permanent
firewall-cmd --add-port=10051/tcp --permanent
firewall-cmd --reload

# set SELinux in permissive mode
sed -i "s/^SELINUX=.*$/SELINUX=permissive/" /etc/selinux/config
setenforce 0

#update system
yum update -y

#install SELinux debuging utils
yum -y install policycoreutils-python bzip2 vim nmap yum-utils

# install PostgreSQL 10 repository
rpm -Uvh https://yum.postgresql.org/10/redhat/rhel-7-x86_64/pgdg-centos10-10-2.noarch.rpm

# install zabbix repo
rpm -Uvh http://repo.zabbix.com/zabbix/4.0/rhel/7/x86_64/zabbix-release-4.0-1.el7.noarch.rpm

yum makecache

# install PostgreSQL 10 Server
yum -y install postgresql10-server postgresql10

# initialize database
/usr/pgsql-10/bin/postgresql-10-setup initdb

systemctl start postgresql-10.service
systemctl enable postgresql-10.service

sudo -u postgres bash -c "psql -c \"CREATE USER zabbix WITH PASSWORD 'zabbix';\""
# this will print:
# could not change directory to "/root": Permission denied
# it is OK!

# sudo -u postgres createuser --pwprompt zabbix

sudo -u postgres createdb -O zabbix zabbix

yum -y install zabbix-server-pgsql zabbix-web-pgsql zabbix-agent zabbix-get zabbix-sender


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

# set the frontend
sed -i "s/^.*php_value date.timezone .*$/php_value date.timezone Europe\/Riga/" /etc/httpd/conf.d/zabbix.conf


cp /var/lib/pgsql/10/data/{pg_hba.conf,pg_hba.conf.original}
cat <<'EOF'> /var/lib/pgsql/10/data/pg_hba.conf
# "local" is for Unix domain socket connections only
local   all             all                                     md5
# IPv4 local connections:
host    all             all             127.0.0.1/32            md5
# IPv6 local connections:
host    all             all             ::1/128                 md5
EOF

# start everything after reboot
systemctl restart postgresql-10 zabbix-server zabbix-agent httpd && systemctl enable zabbix-server zabbix-agent httpd

# install vagrant SSH key
mkdir -p ~/.ssh
echo "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA6NF8iallvQVp22WDkTkyrtvp9eWW6A8YVr+kz4TjGYe7gHzIw+niNltGEFHzD8+v1I2YJ6oXevct1YeS0o9HZyN1Q9qgCgzUFtdOKLv6IedplqoPkcmF0aYet2PkEDo3MlTBckFXPITAMzF8dJSIFo9D8HfdOV0IAdx4O7PtixWKn5y2hMNG0zQPyUecp4pzC6kivAIhyfHilFR61RGL+GPXQ2MWZWFYbAGjyiYJnAmCP3NOTd0jMZEnDkbUvxhMmBYSdETk1rRgm+R4LOzFUGaHqHDLKLX+FIPKcF96hrucXzcWyLbIbEgE98OHlnVYCzRdK8jlqm8tehUc9c9WhQ== vagrant insecure public key"> ~/.ssh/authorized_keys
chmod -R 700 ~/.ssh

#decrease grup screen to 0 seconds
sed -i "s/^GRUB_TIMEOUT=.$/GRUB_TIMEOUT=0/" /etc/default/grub
grub2-mkconfig -o /boot/grub2/grub.cfg

# remove old kerels
package-cleanup --oldkernels --count=1 -y
