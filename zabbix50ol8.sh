


systemctl stop zabbix-server zabbix-proxy zabbix-agent2 nginx php-fpm zabbix-agent snmptrapd zabbix-java-gateway
sudo swapoff --all


# Add 4GB of swap space and never check if enough memory is available
sudo dd if=/dev/zero of=/myswap1 bs=1M count=1024 && sudo chown root:root /myswap1 && sudo chmod 0600 /myswap1 && sudo mkswap /myswap1 && sudo swapon /myswap1 && free -m && sudo dd if=/dev/zero of=/myswap2 bs=1M count=1024 && sudo chown root:root /myswap2 && sudo chmod 0600 /myswap2 && sudo mkswap /myswap2 && sudo swapon /myswap2 && free -m && sudo dd if=/dev/zero of=/myswap3 bs=1M count=1024 && sudo chown root:root /myswap3 && sudo chmod 0600 /myswap3 && sudo mkswap /myswap3 && sudo swapon /myswap3 && free -m && sudo dd if=/dev/zero of=/myswap4 bs=1M count=1024 && sudo chown root:root /myswap4 && sudo chmod 0600 /myswap4 && sudo mkswap /myswap4 && sudo swapon /myswap4 && free -m && echo 1 | sudo tee /proc/sys/vm/overcommit_memory
setenforce 0

timedatectl set-timezone Europe/Riga

rpm -Uvh https://repo.zabbix.com/zabbix/5.0/rhel/8/x86_64/zabbix-release-5.0-1.el8.noarch.rpm
rpm -ivh https://dev.mysql.com/get/mysql80-community-release-el8-4.noarch.rpm
# Install the repository RPM:
sudo dnf install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-8-x86_64/pgdg-redhat-repo-latest.noarch.rpm

curl https://packages.microsoft.com/config/rhel/8/prod.repo -o /etc/yum.repos.d/mssql-release.repo

dnf remove unixODBC-utf16 unixODBC-utf16-devel
ACCEPT_EULA=Y dnf install -y msodbcsql18 mssql-tools18

echo 'export PATH="$PATH:/opt/mssql-tools18/bin"' >> ~/.bashrc
source ~/.bashrc





# Disable the built-in PostgreSQL module:
sudo dnf -qy module disable postgresql
dnf -y install epel-release


dnf clean all

dnf -y install vim git \
zabbix-server-mysql \
zabbix-proxy-sqlite3 \
zabbix-java-gateway \
zabbix-web-mysql \
zabbix-nginx-conf \
zabbix-agent \
zabbix-agent2 \
zabbix-get \
zabbix-js \
zabbix-sender \
postgresql13 \
python3 \
python3-pip \
openldap-clients \
net-snmp-utils \
net-snmp-perl \
certbot \
net-snmp \
mysql \
screen \
jq \
tree \
autoconf automake git pkgconf gcc \
libaio \
docker \
libnsl \
mysql-connector-odbc \
postgresql-odbc \
unzip

rpm -ivh oracle-instantclient19.15-basic-19.15.0.0.0-1.x86_64.rpm \
oracle-instantclient19.15-basiclite-19.15.0.0.0-1.x86_64.rpm \
oracle-instantclient19.15-odbc-19.15.0.0.0-1.x86_64.rpm

rpm -ivh https://download.oracle.com/otn_software/linux/instantclient/1915000/oracle-instantclient19.15-basiclite-19.15.0.0.0-1.x86_64.rpm





vim /etc/selinux/config
setenforce 0

systemctl stop zabbix-server zabbix-proxy zabbix-agent zabbix-agent2 nginx php-fpm snmptrapd zabbix-java-gateway
# reconfigure components
cat /root/backup/etc/zabbix/zabbix_agentd.conf > /etc/zabbix/zabbix_agentd.conf
cat /root/backup/etc/zabbix/zabbix_agent2.conf > /etc/zabbix/zabbix_agent2.conf
cat /root/backup/etc/zabbix/zabbix_server.conf > /etc/zabbix/zabbix_server.conf
cat /root/backup/etc/zabbix/zabbix_proxy.conf > /etc/zabbix/zabbix_proxy.conf
cat /root/backup/etc/zabbix/zabbix_java_gateway.conf > /etc/zabbix/zabbix_java_gateway.conf

# repair php-fpm
cat /root/backup/etc/php-fpm.d/zabbix.conf > /etc/php-fpm.d/zabbix.conf
cat /root/backup/etc/php-fpm.d/www.conf > /etc/php-fpm.d/www.conf

cp /root/backup/etc/zabbix/web/zabbix.conf.php /etc/zabbix/web
chown apache. /etc/zabbix/web/zabbix.conf.php

# install old modules
cd /root/backup/usr/share/zabbix/modules && cp -r * /usr/share/zabbix/modules


# repair nginx
cd /root/backup/etc/nginx/conf.d
cat /root/backup/etc/nginx/conf.d/php-fpm.conf > /etc/nginx/conf.d/php-fpm.conf
cat /root/backup/etc/nginx/conf.d/zabbix.conf > /etc/nginx/conf.d/zabbix.conf
cat /root/backup/etc/nginx/conf.d/https.zbx.aigarskadikis.com.443.conf > /etc/nginx/conf.d/https.zbx.aigarskadikis.com.443.conf
mkdir -p /etc/letsencrypt/live/zbx.aigarskadikis.com /etc/letsencrypt/archive/zbx.aigarskadikis.com
cd /root/backup/etc/letsencrypt/archive/zbx.aigarskadikis.com && cp * /etc/letsencrypt/archive/zbx.aigarskadikis.com

cd /root/backup/etc/letsencrypt/live/zbx.aigarskadikis.com && ls -l

# link back currect certificate
ln -s /etc/letsencrypt/archive/zbx.aigarskadikis.com/cert4.pem /etc/letsencrypt/live/zbx.aigarskadikis.com/cert.pem
ln -s /etc/letsencrypt/archive/zbx.aigarskadikis.com/chain4.pem /etc/letsencrypt/live/zbx.aigarskadikis.com/chain.pem
ln -s /etc/letsencrypt/archive/zbx.aigarskadikis.com/fullchain4.pem /etc/letsencrypt/live/zbx.aigarskadikis.com/fullchain.pem
ln -s /etc/letsencrypt/archive/zbx.aigarskadikis.com/privkey4.pem /etc/letsencrypt/live/zbx.aigarskadikis.com/privkey.pem

nginx -t



cat /root/backup/etc/snmp/snmptrapd.conf > /etc/snmp/snmptrapd.conf
cat /root/backup/etc/zabbix/zabbix_java_gateway.conf > /etc/zabbix/zabbix_java_gateway.conf


cd /root/backup/var/lib/zabbix/.ssh
mkdir -p /var/lib/zabbix/.ssh
mv * /var/lib/zabbix/.ssh
chown -R zabbix. /var/lib/zabbix


systemctl enable --now zabbix-server zabbix-proxy zabbix-agent zabbix-agent2 nginx php-fpm snmptrapd zabbix-java-gateway
systemctl enable zabbix-server zabbix-proxy zabbix-agent zabbix-agent2 nginx php-fpm snmptrapd zabbix-java-gateway

# disabled/optional services
systemctl disable snmpd

curl https://rclone.org/install.sh | sudo bash
cd /root/backup/root/.config/rclone
mkdir -p /root/.config/rclone
cp rclone.conf /root/.config/rclone


# register git ssh key
ssh-keygen -t rsa -b 4096 -C "aigars.kadikis@gmail.com"
cat ~/.ssh/id_rsa.pub
enter key at https://github.com/settings/keys

cd /root/backup/root/.ssh
mv * /root/.ssh

cat /root/backup/etc/profile.d/postgres.sh > /etc/profile.d/postgres.sh

cat /root/backup/etc/sysctl.d/97-zabbix-web-server.conf > /etc/sysctl.d/97-zabbix-web-server.conf
cat /root/backup/etc/sysctl.d/98-zabbix.conf > /etc/sysctl.d/98-zabbix.conf
sysctl --system

mv /root/backup/etc/cron.d/* /etc/cron.d

mv /root/backup/root/.gitconfig ~
mv /root/backup/root/.my.cnf ~
mv /root/backup/root/.pgpass ~

cd /usr/lib/zabbix && rm -rf alertscripts externalscripts

cd /root/backup/usr/lib/zabbix && mv * /usr/lib/zabbix
mv .git /usr/lib/zabbix
mv .gitattributes /usr/lib/zabbix

cd /root/backup/usr/local/bin && mv * /usr/local/bin
cd /root/backup/etc/ssh/ssh_config.d && mv * /etc/ssh/ssh_config.d

cat /root/backup/etc/hosts > /etc/hosts


cd /usr/lib/oracle/19.15/client64/bin

./odbc_update_ini.sh / /usr/lib/oracle/19.15/client64/bin


cd /root/backup/etc/zabbix && mv backup_zabbix_* /etc/zabbix/

cd /etc/sudoers.d
echo 'zabbix ALL=(ALL) NOPASSWD: /usr/sbin/zabbix_proxy -R config_cache_reload' | sudo tee zabbix_proxy_config_cache_reload
chmod 0440 zabbix_proxy_config_cache_reload

cd /etc/sudoers.d
echo 'zabbix ALL=(ALL) NOPASSWD: /usr/sbin/zabbix_server -R config_cache_reload' | sudo tee zabbix_server_config_cache_reload
chmod 0440 zabbix_server_config_cache_reload



