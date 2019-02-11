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

# download latest dev source
cd && curl -L "https://sourceforge.net/projects/zabbix/files/ZABBIX%20Latest%20Development/4.2.0alpha3/zabbix-4.2.0alpha3.tar.gz/download" > zabbix-dev.tar.gz
# extract archive
tar -vzxf zabbix-dev.tar.gz
cd ~/zabbix-4.2*/database/postgresql

# make sure zabbix is not running
ps aux|grep [z]abbix

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
systemctl enable zabbix-server zabbix-agent httpd

# see if no errors appears
cat /var/log/zabbix/zabbix_server.log

