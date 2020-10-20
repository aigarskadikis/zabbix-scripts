#!/bin/bash

# mariadbversion 10.3.17
SELECT();

# SELECT POSTGRES version
SELECT();


# database size, biggest tables
SELECT table_name,
       table_rows,
       data_length,
       index_length,
       round(((data_length + index_length) / 1024 / 1024 / 1024),2) "Size in GB"
FROM information_schema.tables
WHERE table_schema = "zabbix"
ORDER BY round(((data_length + index_length) / 1024 / 1024 / 1024),2) DESC
LIMIT 20;


# create stock database with different DB name in same MariaDB engine (simulate test much faster)

# authorize in postgresSQL server

# make sure MariaDB server is reachable over 3306

# create pgloader profile

# install utility 'screen'

# determine no tables too much



# yum install https://download.postgresql.org/pub/repos/yum/reporpms/EL-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm
# yum install postgresql12-server
# /usr/pgsql-12/bin/postgresql-12-setup initdb
# systemctl enable postgresql-12
# systemctl start postgresql-12


# yum install pgloader

# pgloader -V
# pgloader version "3.6.2"


# replace binaries


