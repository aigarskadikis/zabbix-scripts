#!/bin/bash

# pg11 is already installed
# to setup timescale
# https://docs.timescale.com/v1.2/getting-started/installation/rhel-centos/installation-yum

# stop every process which works with database
systemctl stop zabbix-server zabbix-agent httpd

# system must be up to date
yum -y update

# remove zabbix repository
yum -y remove zabbix-release

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

# install 4.2 repo
rpm -ivh http://repo.zabbix.com/zabbix/4.1/rhel/7/x86_64/zabbix-release-4.1-1.el7.noarch.rpm

# clean and re-create cache
yum clean all && rm -rf /var/cache/yum && yum -y makecache fast

# upgrade zabbix instance
yum -y update

# clear log
> /var/log/zabbix/zabbix_server.log

# execute upgrade
systemctl start zabbix-server

# see if no errors appears
cat /var/log/zabbix/zabbix_server.log

# stop and disable server
systemctl stop zabbix-server zabbix-agent httpd
systemctl disable zabbix-server zabbix-agent httpd

# restore back the default pg conf
cat /var/lib/pgsql/11/data/pg_hba.conf.original > /var/lib/pgsql/11/data/pg_hba.conf

# install timescale feature
yum -y install timescaledb-postgresql-11

find / -name pg_config

PATH=$PATH:/usr/pgsql-11/bin

# enable timescale in database engine
timescaledb-tune

# restart client to take the effect
systemctl restart postgresql-11

# prevent errors about PostgreSQL home dir in next step
cd /var/lib/pgsql

# enable extension for database 'zabbix'
echo "CREATE EXTENSION IF NOT EXISTS timescaledb CASCADE;" | sudo -u postgres psql zabbix

# download latest dev source
cd && curl -L "https://sourceforge.net/projects/zabbix/files/ZABBIX%20Latest%20Development/4.2.0alpha3/zabbix-4.2.0alpha3.tar.gz/download" > zabbix-dev.tar.gz
# extract archive
tar -vzxf zabbix-dev.tar.gz
cd ~/zabbix-4.2*/database/postgresql

# make sure zabbix is not running
ps aux|grep [z]abbix

# patch database. make sure that no precesses (server or httpd) are using database
cat timescaledb.sql | sudo -u zabbix psql zabbix

# this may say:
# ERROR:  column "db_extension" of relation "config" does not exist
# LINE 1: UPDATE config SET db_extension='timescaledb',hk_history_glob
# this can mean that this is not 4.2

# allow to frontend to access database
cat <<'EOF'> /var/lib/pgsql/11/data/pg_hba.conf
# "local" is for Unix domain socket connections only
local   all             all                                     md5
# IPv4 local connections:
host    all             all             127.0.0.1/32            md5
# IPv6 local connections:
host    all             all             ::1/128                 md5
EOF

systemctl restart postgresql-11

# clear log
> /var/log/zabbix/zabbix_server.log

# start server
systemctl start zabbix-server zabbix-agent httpd

# see if no errors appears
cat /var/log/zabbix/zabbix_server.log

