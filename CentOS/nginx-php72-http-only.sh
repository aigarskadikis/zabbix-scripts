#!/bin/bash

systemctl enable firewalld
systemctl start firewalld

# configure firewall rules
firewall-cmd --permanent --add-service=http
firewall-cmd --reload

# make sure system is up to date
yum -y update

# disable selinux
setenforce 0

# set the version we are interested
# ver=$1
ver=4.0.5

yum -y install policycoreutils-python bzip2 nmap vim net-tools

# add zabbix 4.0 repository
rpm -ivh http://repo.zabbix.com/zabbix/4.0/rhel/7/x86_64/zabbix-release-4.0-1.el7.noarch.rpm

# install nginx repo
cat <<'EOF'> /etc/yum.repos.d/nginx.repo
[nginx]
name=nginx repo
baseurl=https://nginx.org/packages/centos/7/$basearch/
gpgcheck=0
enabled=1
EOF

# install mariadb repo
cat <<'EOF'> /etc/yum.repos.d/MariaDB.repo
# MariaDB 10.3 CentOS repository list - created 2018-05-31 08:48 UTC
# http://downloads.mariadb.org/mariadb/repositories/
[mariadb]
name = MariaDB
baseurl = http://yum.mariadb.org/10.3/centos7-amd64
gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
gpgcheck=1
EOF

# configure php72 repo
yum -y install epel-release
rpm -Uvh https://mirror.webtatic.com/yum/el7/webtatic-release.rpm

yum clean all && rm -rf /var/cache/yum && yum makecache fast

# install mariadb (mysql database engine for CentOS 7)
yum -y install MariaDB-server MariaDB-client

systemctl start mariadb

#create zabbix database
mysql <<< 'drop database zabbix;'

mysql <<< 'create database zabbix character set utf8 collate utf8_bin;'

#create user zabbix and allow user to connect to the database with only from localhost
mysql <<< 'grant all privileges on zabbix.* to "zabbix"@"localhost" identified by "zabbix";'

#refresh permissions
mysql <<< 'flush privileges;'


#show existing databases
mysql <<< 'show databases;' | grep zabbix

#enable to start MySQL automatically at next boot
systemctl enable mariadb


yum -y install zabbix-server-mysql-$ver

ls -l /usr/share/doc/zabbix-server-mysql*/
zcat /usr/share/doc/zabbix-server-mysql*/create.sql.gz | mysql -uzabbix -pzabbix zabbix

#define server conf file
server=/etc/zabbix/zabbix_server.conf

grep "^DBPassword=" $server
if [ $? -eq 0 ]; then
sed -i "s/^DBPassword=.*/DBPassword=zabbix/" $server #modifies already customized setting
else
ln=$(grep -n "DBPassword=" $server | egrep -o "^[0-9]+"); ln=$((ln+1)) #calculate the the line number after default setting
sed -i "`echo $ln`iDBPassword=zabbix" $server #adds new line
fi

grep "^CacheUpdateFrequency=" $server
if [ $? -eq 0 ]; then
sed -i "s/^CacheUpdateFrequency=.*/CacheUpdateFrequency=4/" $server #modifies already customized setting
else
ln=$(grep -n "CacheUpdateFrequency=" $server | egrep -o "^[0-9]+"); ln=$((ln+1)) #calculate the the line number after default setting
sed -i "`echo $ln`iCacheUpdateFrequency=4" $server #adds new line
fi

#show zabbix server conf file
grep -v "^$\|^#" $server

#start zabbix-server instance
systemctl start zabbix-server && sleep 1

cat /var/log/zabbix/zabbix_server.log

systemctl status zabbix-server

systemctl enable zabbix-server

# install zabbix frontend
yum -y install nginx
yum search fpm
yum -y install php72w-fpm

# check changes on service list
ls -l /usr/lib/systemd/system|grep php

# check the ports on listening state
netstat -tulpn

systemctl start php-fpm
# this will start php-fpm daemon to listen on port 9000
netstat -tulpn

# install frontend
yum -y install zabbix-web-mysql-$ver

systemctl stop httpd && systemctl disable httpd

systemctl status nginx && systemctl stop nginx 

# remove defaul conf
cp /etc/nginx/conf.d/default.conf ~
rm -rf /etc/nginx/conf.d/default.conf

cd /etc/nginx/conf.d

cat << 'EOF' > zbx_http_only.conf
server {
        listen          0.0.0.0:80;
        index           index.php;

        set $webroot '/usr/share/zabbix';

        access_log      /var/log/nginx/zabbix_access.log main;
        error_log       /var/log/nginx/zabbix_error.log error;

        root $webroot;

        charset utf8;

        large_client_header_buffers 8 8k;

        client_max_body_size 10M;

        location = /favicon.ico {
                log_not_found off;
        }

        location / {
                index   index.php;
                try_files       $uri $uri/      =404;
        }

        location ~* ^.+.(js|css|png|jpg|jpeg|gif|ico)$ {
                access_log      off;
                expires         10d;
        }

        location ~ /\. {
                access_log off;
                log_not_found off;
                deny all;
        }

        location ~ /(api\/|conf[^\.]|include|locale) {
                deny all;
                return 404;
        }

        location ~ [^/]\.php(/|$) {
                fastcgi_pass    127.0.0.1:9000;

                fastcgi_split_path_info ^(.+\.php)(/.+)$;
                fastcgi_index  index.php;

                fastcgi_param  DOCUMENT_ROOT    $webroot;
                fastcgi_param  SCRIPT_FILENAME  $webroot$fastcgi_script_name;
                fastcgi_param  PATH_TRANSLATED  $webroot$fastcgi_script_name;

                include fastcgi_params;
                fastcgi_param  QUERY_STRING     $query_string;
                fastcgi_param  REQUEST_METHOD   $request_method;
                fastcgi_param  CONTENT_TYPE     $content_type;
                fastcgi_param  CONTENT_LENGTH   $content_length;

                fastcgi_intercept_errors        on;
                fastcgi_ignore_client_abort     off;
                fastcgi_connect_timeout 60;
                fastcgi_send_timeout 180;
                fastcgi_read_timeout 180;
                fastcgi_buffer_size 128k;
                fastcgi_buffers 4 256k;
                fastcgi_busy_buffers_size 256k;
                fastcgi_temp_file_write_size 256k;

                fastcgi_param PHP_VALUE "
                        max_execution_time = 300
                        memory_limit = 128M
                        post_max_size = 16M
                        upload_max_filesize = 2M
                        max_input_time = 300
                        date.timezone = EST
                        always_populate_raw_post_data = -1
                ";
        }

        location /server-status {
                stub_status on;
                access_log   off;
                allow 127.0.0.1;
                deny all;
        }

        location /php-fpm-status {
                fastcgi_param  DOCUMENT_ROOT    $webroot;
                fastcgi_param  SCRIPT_FILENAME  $webroot$fastcgi_script_name;
                fastcgi_param  PATH_TRANSLATED  $webroot$fastcgi_script_name;

                include fastcgi_params;
                fastcgi_param  QUERY_STRING     $query_string;
                fastcgi_param  REQUEST_METHOD   $request_method;
                fastcgi_param  CONTENT_TYPE     $content_type;
                fastcgi_param  CONTENT_LENGTH   $content_length;

                access_log off;

                allow 127.0.0.1;
                deny all;

                include fastcgi_params;
                fastcgi_pass    127.0.0.1:9000;
        }
}
EOF

# configure frontend
cat > /etc/zabbix/web/zabbix.conf.php << EOF
<?php
// Zabbix GUI configuration file.
global \$DB;

\$DB['TYPE']     = 'MYSQL';
\$DB['SERVER']   = 'localhost';
\$DB['PORT']     = '0';
\$DB['DATABASE'] = 'zabbix';
\$DB['USER']     = 'zabbix';
\$DB['PASSWORD'] = 'zabbix';

// Schema name. Used for IBM DB2 and PostgreSQL.
\$DB['SCHEMA'] = '';

\$ZBX_SERVER      = 'localhost';
\$ZBX_SERVER_PORT = '10051';
\$ZBX_SERVER_NAME = '$1';

\$IMAGE_FORMAT_DEFAULT = IMAGE_FORMAT_PNG;
EOF

systemctl restart nginx php-fpm
systemctl enable nginx php-fpm

yum -y install zabbix-agent-$ver

#define agent conf file
agent=/etc/zabbix/zabbix_agentd.conf

grep "^EnableRemoteCommands=" $agent
if [ $? -eq 0 ]; then
sed -i "s/^EnableRemoteCommands=.*/EnableRemoteCommands=1/" $agent #modifies already customized setting
else
ln=$(grep -n "EnableRemoteCommands=" $agent | egrep -o "^[0-9]+"); ln=$((ln+1)) #calculate the the line number after default setting
sed -i "`echo $ln`iEnableRemoteCommands=1" $agent #adds new line
fi

yum -y install zabbix-sender-$ver
yum -y install zabbix-get-$ver
systemctl start zabbix-agent
systemctl enable zabbix-agent
