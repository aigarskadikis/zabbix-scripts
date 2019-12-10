#!/bin/bash

# install GPG key
rpm --import http://yum.mariadb.org/RPM-GPG-KEY-MariaDB

# install repositoru
cat <<'EOF'> /etc/yum.repos.d/MariaDB.repo
[mariadb]
name = MariaDB-10.3.16
baseurl=http://yum.mariadb.org/10.3.16/centos7-amd64
# alternative: baseurl=http://archive.mariadb.org/mariadb-10.3.16/yum/centos7-amd64
gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
gpgcheck=1
EOF

# install nginx repo
cat <<'EOF'> /etc/yum.repos.d/nginx.repo
[nginx]
name=nginx repo
baseurl=http://nginx.org/packages/mainline/rhel/7/$basearch/
gpgcheck=0
enabled=1
EOF

# install zabbix 4.0 repository
rpm -Uvh https://repo.zabbix.com/zabbix/4.0/rhel/7/x86_64/zabbix-release-4.0-2.el7.noarch.rpm 

# crean previous yum cache
yum clean all

# create cache
yum makecache

# install some conviences
yum -y install vim net-tools

# install mariadb server
yum -y install MariaDB-client

# install zabbix frontend and disable drefault httpd (we will use nginx instead)
yum -y install zabbix-web-mysql zabbix-web
systemctl stop httpd
systemctl disable httpd

# install nginx
yum -y install nginx php-fpm

# configure nginx
cd /etc/php-fpm.d
cat <<'EOF'> zabbix.conf
[zabbix]
user = apache
group = apache

listen = /run/php-fpm/zabbix.sock
listen.owner = nginx
listen.allowed_clients = 127.0.0.1

pm = dynamic
pm.max_children = 50
pm.start_servers = 5
pm.min_spare_servers = 5
pm.max_spare_servers = 35

php_value[session.save_handler] = files
php_value[session.save_path]    = /var/lib/php/session

php_value[max_execution_time] = 300
php_value[memory_limit] = 2G
php_value[post_max_size] = 16M
php_value[upload_max_filesize] = 20M
php_value[max_input_time] = 300
php_value[max_input_vars] = 100000
php_value[date.timezone] = EST
EOF

# move to nginx conf dir
cd /etc/nginx/conf.d

# remove default profile
rm -f default.conf

# set nginx profile
cat <<'EOF'> zabbix.conf
server {
#        listen          80;
#        server_name     example.com;

        root    /usr/share/zabbix;

        index   index.php;

        location = /favicon.ico {
                log_not_found   off;
        }

        location / {
                try_files       $uri $uri/ =404;
        }

        location /assets {
                access_log      off;
                expires         10d;
        }

        location ~ /\.ht {
                deny            all;
        }

        location ~ /(api\/|conf[^\.]|include|locale) {
                deny            all;
                return          404;
        }

        location ~ [^/]\.php(/|$) {
                fastcgi_pass    unix:/run/php-fpm/zabbix.sock;
                fastcgi_split_path_info ^(.+\.php)(/.+)$;
                fastcgi_index   index.php;

                fastcgi_param   DOCUMENT_ROOT   /usr/share/zabbix;
                fastcgi_param   SCRIPT_FILENAME /usr/share/zabbix$fastcgi_script_name;
                fastcgi_param   PATH_TRANSLATED /usr/share/zabbix$fastcgi_script_name;

                include fastcgi_params;
                fastcgi_param   QUERY_STRING    $query_string;
                fastcgi_param   REQUEST_METHOD  $request_method;
                fastcgi_param   CONTENT_TYPE    $content_type;
                fastcgi_param   CONTENT_LENGTH  $content_length;

                fastcgi_intercept_errors        on;
                fastcgi_ignore_client_abort     off;
                fastcgi_connect_timeout         60;
                fastcgi_send_timeout            180;
                fastcgi_read_timeout            180;
                fastcgi_buffer_size             128k;
                fastcgi_buffers                 4 256k;
                fastcgi_busy_buffers_size       256k;
                fastcgi_temp_file_write_size    256k;
        }
}
EOF

# configure access to database
cd /etc/zabbix/web
cat <<'EOF'> zabbix.conf.php
<?php
// Zabbix GUI configuration file.
global $DB;

$DB['TYPE']     = 'MYSQL';
$DB['SERVER']   = '10.79.7.37';
$DB['PORT']     = '0';
$DB['DATABASE'] = 'zabbix';
$DB['USER']     = 'zabbix';
$DB['PASSWORD'] = 'zabbix';

// Schema name. Used for IBM DB2 and PostgreSQL.
$DB['SCHEMA'] = '';

$ZBX_SERVER      = '10.79.29.38';
$ZBX_SERVER_PORT = '10051';
$ZBX_SERVER_NAME = '';

$IMAGE_FORMAT_DEFAULT = IMAGE_FORMAT_PNG;
EOF

# restart nginx
systemctl restart php-fpm nginx

# check if web server is listening on port 80
netstat -tulpn|grep 80

# test if there is zabbix fronend serving
curl -kL http://127.0.0.1 | grep -i zabbix

