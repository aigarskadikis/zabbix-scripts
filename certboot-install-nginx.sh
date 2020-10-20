#!/bin/bash

# zabbix speed install with validation

echo 1 | sudo tee /proc/sys/vm/overcommit_memory
sudo dd if=/dev/zero of=/myswap1 bs=1M count=1024 && sudo chown root:root /myswap1 && sudo chmod 0600 /myswap1 && sudo mkswap /myswap1 && sudo swapon /myswap1 && free -m
sudo dd if=/dev/zero of=/myswap2 bs=1M count=1024 && sudo chown root:root /myswap2 && sudo chmod 0600 /myswap2 && sudo mkswap /myswap2 && sudo swapon /myswap2 && free -m


rpm -Uvh https://dev.mysql.com/get/mysql80-community-release-el7-3.noarch.rpm
rpm -Uvh https://repo.zabbix.com/zabbix/5.0/rhel/7/x86_64/zabbix-release-5.0-1.el7.noarch.rpm
# https://www.postgresql.org/download/linux/redhat/
yum install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm

/usr/pgsql-12/bin/postgresql-12-setup initdb
systemctl enable postgresql-12
systemctl start postgresql-12


yum clean all

yum install -y python36 vim centos-release-scl zabbix-server-mysql zabbix-server-pgsql zabbix-agent screen

vim /etc/yum.repos.d/zabbix.repo
[zabbix-frontend]
enabled=1

yum install -y zabbix-web-mysql-scl zabbix-nginx-conf-scl

yum -y install mysql-community-server && systemctl enable mysqld && systemctl start mysqld

#open different schell

vim /etc/opt/rh/rh-php72/php-fpm.d/zabbix.conf
listen.acl_users = apache,nginx
php_value[memory_limit] = 2G
php_value[date.timezone] = Europe/Riga

vim /etc/opt/rh/rh-nginx116/nginx/conf.d/zabbix.conf
        listen          80;
        server_name     next.catonrug.net;

vim /etc/zabbix/zabbix_server.conf
DBPassword=z4bbi#SIA

systemctl restart zabbix-server zabbix-agent rh-nginx116-nginx rh-php72-php-fpm
curl -Lsk http://next.catonrug.net | grep Zabbix


cd /etc/my.cnf.d

cat << 'EOF' > performance_schema.cnf
[mysqld]
performance_schema = 0
EOF

cat << 'EOF' > disable_binary_log.cnf
[mysqld]
disable_log_bin
EOF

cat << 'EOF' > secure_file_priv.cnf
[mysqld]
secure-file-priv=/tmp
EOF

cat << 'EOF' > mysql_native_password.cnf
[mysqld]
default-authentication-plugin=mysql_native_password
EOF

grep "temporary password" /var/log/mysqld.log | sed "s|^.*localhost:.||" | xargs -i echo "/usr/bin/mysqladmin -u root password 'z4bbi#SIA' -p'{}'" | sudo bash
cat << 'EOF' > ~/.my.cnf
[client]
user=root
password='z4bbi#SIA'
EOF

mysql
CREATE USER "zabbix"@"localhost" IDENTIFIED BY "z4bbi#SIA";
ALTER USER "zabbix"@"localhost" IDENTIFIED WITH mysql_native_password BY "z4bbi#SIA";
CREATE DATABASE zabbix CHARACTER SET utf8 COLLATE utf8_bin;
GRANT SELECT, UPDATE, DELETE, INSERT, CREATE, DROP, ALTER, INDEX, REFERENCES ON zabbix.* TO "zabbix"@"localhost";
FLUSH PRIVILEGES;
exit

mysql_secure_installation

zcat /usr/share/doc/zabbix-server-mysql*/create.sql.gz | mysql zabbix

#set selinux exceptions for httpd
getsebool -a | grep "httpd_can_network_connect \|zabbix_can_network"
setsebool -P httpd_can_network_connect on
setsebool -P zabbix_can_network on
getsebool -a | grep "httpd_can_network_connect \|zabbix_can_network"

setenforce 0
systemctl restart zabbix-server zabbix-agent rh-nginx116-nginx rh-php72-php-fpm

systemctl enable zabbix-server zabbix-agent rh-nginx116-nginx rh-php72-php-fpm

tail -99 /var/log/zabbix/zabbix_server.log


curl -s https://dl.eff.org/certbot-auto -o /usr/bin/certbot-auto
chmod +x /usr/bin/certbot-auto 

USE_PYTHON_3=1 certbot-auto certonly --webroot -w /usr/share/zabbix -d next.catonrug.net

   /etc/letsencrypt/live/next.catonrug.net/fullchain.pem
   /etc/letsencrypt/live/next.catonrug.net/privkey.pem

cat << 'EOF' > /etc/opt/rh/rh-nginx116/nginx/conf.d/http.next.catonrug.net.conf
server {
listen next.catonrug.net:80;
server_name next.catonrug.net;
rewrite ^ https://$server_name$request_uri? permanent;
}
EOF

vim /etc/opt/rh/rh-nginx116/nginx/conf.d/zabbix.conf
listen          443 ssl;

        ssl_certificate      /etc/letsencrypt/live/next.catonrug.net/fullchain.pem;
        ssl_certificate_key  /etc/letsencrypt/live/next.catonrug.net/privkey.pem;

systemctl reload rh-nginx116-nginx


yum install -y policycoreutils-python
audit2allow -a | grep -v "===\|^$" | sed -e '/#!!!!/,+1d'
allow httpd_t zabbix_port_t:tcp_socket name_connect;
grep "comm.*zabbix_server.*zabbix_t" /var/log/audit/audit.log | audit2allow -M comm_zabbix_server_zabbix_t
semodule -i comm_zabbix_server_zabbix_t.pp


https://ssl-config.mozilla.org/#server=nginx&version=1.17.7&config=intermediate&openssl=1.1.1d&guideline=5.6


echo "* * * * * root USE_PYTHON_3=1 certbot-auto renew" | sudo tee /etc/cron.d/0007_letsencrypt_renewal

tail -f /var/log/cron

tail -f /var/log/letsencrypt/letsencrypt.log




