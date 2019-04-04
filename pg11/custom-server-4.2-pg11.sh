#!/bin/bash

# cd && curl https://raw.githubusercontent.com/catonrug/zabbix-scripts/master/pg11/custom-server-4.0-LTS-pg11.sh > install.sh && chmod +x install.sh && time ./install.sh

# to setup timescale
# https://docs.timescale.com/v1.2/getting-started/installation/rhel-centos/installation-yum

# open 80 and 443 into firewall
systemctl enable firewalld && systemctl start firewalld

firewall-cmd --permanent --add-service=http
firewall-cmd --permanent --add-service=https
firewall-cmd --add-port=10051/tcp --permanent
firewall-cmd --reload

# set SELinux in permissive mode
sed -i "s/^SELINUX=.*$/SELINUX=permissive/" /etc/selinux/config
setenforce 0

# update system
yum update -y

# install SELinux debuging utils
yum -y install policycoreutils-python bzip2 vim nmap yum-utils

# install PostgreSQL 11 repository
rpm -Uvh https://yum.postgresql.org/11/redhat/rhel-7-x86_64/pgdg-centos11-11-2.noarch.rpm

# install timescale repo
cat > /etc/yum.repos.d/timescale_timescaledb.repo <<EOL
[timescale_timescaledb]
name=timescale_timescaledb
baseurl=https://packagecloud.io/timescale/timescaledb/el/7/\$basearch
repo_gpgcheck=1
gpgcheck=0
enabled=1
gpgkey=https://packagecloud.io/timescale/timescaledb/gpgkey
sslverify=1
sslcacert=/etc/pki/tls/certs/ca-bundle.crt
metadata_expire=300
EOL

# install zabbix repo
rpm -Uvh http://repo.zabbix.com/zabbix/4.2/rhel/7/x86_64/zabbix-release-4.2-1.el7.noarch.rpm

yum makecache fast

# install PostgreSQL 11 Server
yum -y install postgresql11-server postgresql11

# initialize database
/usr/pgsql-11/bin/postgresql-11-setup initdb

systemctl status postgresql-11 && systemctl stop postgresql-11

# set permissions
cat <<'EOF'> /var/lib/pgsql/11/data/pg_hba.conf
local   all             all                                     trust
host    all             all             127.0.0.1/32            trust
host    all             all             ::1/128                 trust
EOF

systemctl start postgresql-11 && systemctl enable postgresql-11

# let's move to default postgresql dir
cd /var/lib/pgsql

# create database user
# 
sudo -u postgres bash -c "psql -c \"CREATE USER zabbix WITH PASSWORD 'zabbix';\""

# sudo -u postgres bash -c "psql -c \"DROP DATABASE IF EXISTS zabbix;\""

# create database 'zabbix'. owner is user 'zabbix'
sudo -u postgres createdb -O zabbix zabbix

# install server
yum -y install zabbix-server-pgsql zabbix-web-pgsql zabbix-agent zabbix-get zabbix-sender

# install schema
zcat /usr/share/doc/zabbix-server-pgsql*/create.sql.gz | sudo -u zabbix psql zabbix

# install timescale feature
yum -y install timescaledb-postgresql-11

find / -name pg_config

PATH=$PATH:/usr/pgsql-11/bin

# enable timescale in database engine
timescaledb-tune
# Using postgresql.conf at this path:
# /var/lib/pgsql/11/data/postgresql.conf
# 
# Is this correct? [(y)es/(n)o]: y
# Writing backup to:
# /tmp/timescaledb_tune.backup201902110933
# 
# shared_preload_libraries needs to be updated
# Current:
# #shared_preload_libraries = ''
# Recommended:
# shared_preload_libraries = 'timescaledb'
# Is this okay? [(y)es/(n)o]: y
# success: shared_preload_libraries will be updated
# 
# Tune memory/parallelism/WAL and other settings? [(y)es/(n)o]: n
# Saving changes to: /var/lib/pgsql/11/data/postgresql.conf

# restart client to take the effect
systemctl restart postgresql-11

# prevent errors about PostgreSQL home dir in next step
cd /var/lib/pgsql

# enable extension for database 'zabbix'
echo "CREATE EXTENSION IF NOT EXISTS timescaledb CASCADE;" | sudo -u postgres psql zabbix
# WARNING:
# WELCOME TO
#  _____ _                               _     ____________
# |_   _(_)                             | |    |  _  \ ___ \
#   | |  _ _ __ ___   ___  ___  ___ __ _| | ___| | | | |_/ /
#   | | | |  _ ` _ \ / _ \/ __|/ __/ _` | |/ _ \ | | | ___ \
#   | | | | | | | | |  __/\__ \ (_| (_| | |  __/ |/ /| |_/ /
#   |_| |_|_| |_| |_|\___||___/\___\__,_|_|\___|___/ \____/
#                Running version 1.2.0
# For more information on TimescaleDB, please visit the following links:
# 
#  1. Getting started: https://docs.timescale.com/getting-started
#  2. API reference documentation: https://docs.timescale.com/api
#  3. How TimescaleDB is designed: https://docs.timescale.com/introduction/architecture
# 
# Note: TimescaleDB collects anonymous reports to better understand and assist our users.
# For more information and how to disable, please see our docs https://docs.timescaledb.com/using-timescaledb/telemetry.
# 
# CREATE EXTENSION



# download latest source
cd && curl -L "https://sourceforge.net/projects/zabbix/files/ZABBIX%20Latest%20Stable/4.2.0/zabbix-4.2.0.tar.gz/download" > zabbix-source.tar.gz
# extract archive
tar -vzxf zabbix-source.tar.gz
cd ~/zabbix-4.2*/database/postgresql
cp timescaledb.sql /var/lib/pgsql

# make sure zabbix is not running
ps aux|grep [z]abbix_server

# patch database. make sure that no precesses (server or httpd) are using database
cd /var/lib/pgsql
cat timescaledb.sql | sudo -u zabbix psql zabbix
# NOTICE:  migrating data to chunks
# DETAIL:  Migration might take a while depending on the amount of data.
#   create_hypertable
# ----------------------
#  (1,public,history,t)
# (1 row)
# 
#                    set_adaptive_chunking
# ------------------------------------------------------------
#  (_timescaledb_internal.calculate_chunk_interval,120795955)
# (1 row)
# 
# NOTICE:  migrating data to chunks
# DETAIL:  Migration might take a while depending on the amount of data.
#      create_hypertable
# ---------------------------
#  (2,public,history_uint,t)
# (1 row)
# 
#                    set_adaptive_chunking
# ------------------------------------------------------------
#  (_timescaledb_internal.calculate_chunk_interval,120795955)
# (1 row)
# 
#     create_hypertable
# --------------------------
#  (3,public,history_log,t)
# (1 row)
# 
#                    set_adaptive_chunking
# ------------------------------------------------------------
#  (_timescaledb_internal.calculate_chunk_interval,120795955)
# (1 row)
# 
#      create_hypertable
# ---------------------------
#  (4,public,history_text,t)
# (1 row)
# 
#                    set_adaptive_chunking
# ------------------------------------------------------------
#  (_timescaledb_internal.calculate_chunk_interval,120795955)
# (1 row)
# 
#     create_hypertable
# --------------------------
#  (5,public,history_str,t)
# (1 row)
# 
#                    set_adaptive_chunking
# ------------------------------------------------------------
#  (_timescaledb_internal.calculate_chunk_interval,120795955)
# (1 row)
# 
# NOTICE:  migrating data to chunks
# DETAIL:  Migration might take a while depending on the amount of data.
#   create_hypertable
# ---------------------
#  (6,public,trends,t)
# (1 row)
# 
#                    set_adaptive_chunking
# ------------------------------------------------------------
#  (_timescaledb_internal.calculate_chunk_interval,120795955)
# (1 row)
# 
# NOTICE:  migrating data to chunks
# DETAIL:  Migration might take a while depending on the amount of data.
#     create_hypertable
# --------------------------
#  (7,public,trends_uint,t)
# (1 row)
# 
#                    set_adaptive_chunking
# ------------------------------------------------------------
#  (_timescaledb_internal.calculate_chunk_interval,120795955)
# (1 row)
# 
# UPDATE 1


# if this says:
# ERROR:  column "db_extension" of relation "config" does not exist
# LINE 1: UPDATE config SET db_extension='timescaledb',hk_history_glob
# this can mean that this is not 4.2


# install aditional modules for python
# yum -y install epel-release && yum -y install python2-pyyaml python-psycopg2 pytz

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

# allow httpd to connect to pg database
cp /var/lib/pgsql/11/data/{pg_hba.conf,pg_hba.conf.original}
cat <<'EOF'> /var/lib/pgsql/11/data/pg_hba.conf
local   all             all                                     trust
host    all             all             127.0.0.1/32            trust
host    all             all             ::1/128                 trust
EOF

cat <<'EOF'> /etc/zabbix/web/zabbix.conf.php
<?php
// Zabbix GUI configuration file.
global $DB;

$DB['TYPE']     = 'POSTGRESQL';
$DB['SERVER']   = 'localhost';
$DB['PORT']     = '0';
$DB['DATABASE'] = 'zabbix';
$DB['USER']     = 'zabbix';
$DB['PASSWORD'] = 'zabbix';

// Schema name. Used for IBM DB2 and PostgreSQL.
$DB['SCHEMA'] = '';

$ZBX_SERVER      = 'localhost';
$ZBX_SERVER_PORT = '10051';
$ZBX_SERVER_NAME = 'pg11';

$IMAGE_FORMAT_DEFAULT = IMAGE_FORMAT_PNG;
EOF


# start everything after reboot
systemctl restart postgresql-11 zabbix-server zabbix-agent httpd && systemctl enable zabbix-server zabbix-agent httpd

# install vagrant SSH key
mkdir -p ~/.ssh
echo "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA6NF8iallvQVp22WDkTkyrtvp9eWW6A8YVr+kz4TjGYe7gHzIw+niNltGEFHzD8+v1I2YJ6oXevct1YeS0o9HZyN1Q9qgCgzUFtdOKLv6IedplqoPkcmF0aYet2PkEDo3MlTBckFXPITAMzF8dJSIFo9D8HfdOV0IAdx4O7PtixWKn5y2hMNG0zQPyUecp4pzC6kivAIhyfHilFR61RGL+GPXQ2MWZWFYbAGjyiYJnAmCP3NOTd0jMZEnDkbUvxhMmBYSdETk1rRgm+R4LOzFUGaHqHDLKLX+FIPKcF96hrucXzcWyLbIbEgE98OHlnVYCzRdK8jlqm8tehUc9c9WhQ== vagrant insecure public key"> ~/.ssh/authorized_keys
chmod -R 700 ~/.ssh

#decrease grub screen to 0 seconds
sed -i "s/^GRUB_TIMEOUT=.$/GRUB_TIMEOUT=0/" /etc/default/grub
grub2-mkconfig -o /boot/grub2/grub.cfg

# remove old kerels
package-cleanup --oldkernels --count=1 -y
