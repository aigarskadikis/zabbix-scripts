systemctl status apache2
systemctl stop apache2
systemctl status apache2

# remove apache2
apt -y remove apache2

# if previous command did not succeed. see what is using it
ps aux | grep -i [a]pt

# reload repo content
apt -y update

# install nginx
apt -y install nginx php-fpm

# move to home
cd

# download repo
wget http://repo.zabbix.com/zabbix/4.0/ubuntu/pool/main/z/zabbix-release/zabbix-release_4.0-1%2Bxenial_all.deb

# install
dpkg -i zabbix-release_4.0-1+xenial_all.deb

# search if there is some zabbix packages available
apt search zabbix

apt -y install zabbix-frontend-php

# see where the fpm.sock is located and what is exact path
find / -name *fpm.sock


cd /etc/nginx/sites-available

# install zabbix web server directive
cat << 'EOF' > zabbix.conf
server {
listen 80;
root /usr/share/zabbix;
access_log /var/log/nginx/zabbix-access.log;
error_log /var/log/nginx/zabbix-error.log;
index index.php index.html index.htm;
location ~ [^/]\.php(/|$) {
fastcgi_split_path_info ^(.+\.php)(/.+)$;
fastcgi_pass unix:/run/php/php7.0-fpm.sock;
fastcgi_index index.php;
include fastcgi.conf;
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
}
EOF
cat zabbix.conf

# remove default page
rm -rf /etc/nginx/sites-enabled/default

# create zabbix site as an only resource available
ln -s /etc/nginx/sites-available/zabbix.conf /etc/nginx/sites-enabled/zabbix.conf

systemctl restart nginx php7.0-fpm








