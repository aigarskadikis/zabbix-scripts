# install mod SSL:
yum -y install mod_ssl

# move to HTTPD conf dir:
cd /etc/httpd/conf.d

# make inactive original config:
mv ssl.conf conf.ssl

# create dir for self-signed certificate:
mkdir -p /etc/httpd/ssl/private

# set right permissions:
chmod 700 /etc/httpd/ssl/private

# generate certificate:
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/httpd/ssl/private/apache-selfsigned.key -out /etc/httpd/ssl/apache-selfsigned.crt

# install configuration:
cat << 'EOF' > /etc/httpd/conf.d/zabbix.conf
# redirest http to https
<VirtualHost *:80>
RewriteEngine On
RewriteCond %{HTTPS} off
RewriteRule ^(.*)$ https://%{HTTP_HOST}%{REQUEST_URI} [L,R=301]
</VirtualHost>

# settings for https
Listen 443 https
<VirtualHost *:443>
SSLEngine on
SSLProtocol all -SSLv2 -SSLv3
SSLCipherSuite HIGH:3DES:!aNULL:!MD5:!SEED:!IDEA
SSLCertificateFile /etc/httpd/ssl/apache-selfsigned.crt
SSLCertificateKeyFile /etc/httpd/ssl/private/apache-selfsigned.key

DocumentRoot /usr/share/zabbix

<Directory "/usr/share/zabbix">
    Options FollowSymLinks
    AllowOverride None
    Require all granted
    <IfModule mod_php5.c>
        php_value max_execution_time 300
        php_value memory_limit 2G
        php_value post_max_size 16M
        php_value upload_max_filesize 20M
        php_value max_input_time 300
        php_value max_input_vars 100000
        php_value always_populate_raw_post_data -1
        php_value date.timezone Europe/Riga
    </IfModule>
</Directory>

<Directory "/usr/share/zabbix/conf">
    Require all denied
</Directory>

<Directory "/usr/share/zabbix/app">
    Require all denied
</Directory>

<Directory "/usr/share/zabbix/include">
    Require all denied
</Directory>

<Directory "/usr/share/zabbix/local">
    Require all denied
</Directory>
</VirtualHost>
EOF

# check if the sysntax is OK:
apachectl configtest

# restart daemon:
systemctl restart httpd
