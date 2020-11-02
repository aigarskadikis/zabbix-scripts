

# specific timescale and postgres version
# docker run --name pg11ts132 -t -e POSTGRES_PASSWORD="zabbix" -e POSTGRES_DB="dummy_db" -p 17411:5432 -d timescale/timescaledb:1.3.2-pg11



echo 1 | sudo tee /proc/sys/vm/overcommit_memory
sudo dd if=/dev/zero of=/myswap1 bs=1M count=1024 && sudo chown root:root /myswap1 && sudo chmod 0600 /myswap1 && sudo mkswap /myswap1 && sudo swapon /myswap1 && free -m
sudo dd if=/dev/zero of=/myswap2 bs=1M count=1024 && sudo chown root:root /myswap2 && sudo chmod 0600 /myswap2 && sudo mkswap /myswap2 && sudo swapon /myswap2 && free -m

# install zabbix repo. to setup zabbix agent and use native postgres monitoring
rpm -Uvh https://repo.zabbix.com/zabbix/5.0/rhel/8/x86_64/zabbix-release-5.0-1.el8.noarch.rpm

# https://www.postgresql.org/download/linux/redhat/
# Install PostgreSQL repository RPM:
dnf -y install https://download.postgresql.org/pub/repos/yum/reporpms/EL-8-x86_64/pgdg-redhat-repo-latest.noarch.rpm

# Install TimescaleDB repo
sudo tee /etc/yum.repos.d/timescale_timescaledb.repo <<EOL
[timescale_timescaledb]
name=timescale_timescaledb
baseurl=https://packagecloud.io/timescale/timescaledb/el/8/\$basearch
repo_gpgcheck=1
gpgcheck=0
enabled=1
gpgkey=https://packagecloud.io/timescale/timescaledb/gpgkey
sslverify=1
sslcacert=/etc/pki/tls/certs/ca-bundle.crt
metadata_expire=300
EOL

# Clean package manager cache
dnf clean all

# Disable the built-in PostgreSQL module:
dnf -qy module disable postgresql

# install pg 12 server, timescaledb extension, agent2 to natively monitor database
dnf install -y postgresql12-server timescaledb-postgresql-12 zabbix-agent2 vim

# systemctl stop postgresql-12
# rm -rf /var/lib/pgsql/12/data

# initialize database and enable automatic start:
/usr/pgsql-12/bin/postgresql-12-setup initdb

# enable TimescaleDB module
echo "shared_preload_libraries = 'timescaledb'" >> /var/lib/pgsql/12/data/postgresql.conf

# specify/whiteliust the binding address so other remote machines can connect to server
echo "listen_addresses = '0.0.0.0'" >> /var/lib/pgsql/12/data/postgresql.conf

systemctl enable postgresql-12
systemctl start postgresql-12
systemctl status postgresql-12

# check if postgres is listening on IP address
ss --tcp --listen --numeric | grep 5432
# it should not listen on '127.0.0.1'

# navigate to posgres user (root for db engine)
su - postgres




# go to postgres
su - postgres

cd /tmp

# source
# download data from cloud instance
PGHOST=10.133.112.87 PGPORT=7412 PGUSER=postgres PGPASSWORD=zabbix \
pg_dump \
--exclude-schema=_timescaledb_internal \
--exclude-schema=_timescaledb_cache \
--exclude-schema=_timescaledb_catalog \
--exclude-schema=_timescaledb_config \
--exclude-table-data=history* \
--exclude-table-data=trends* \
--data-only \
--dbname=z50 \
--file=/tmp/data.sql

# destination
# create user 'zabbix_user'
PGHOST=10.133.112.87 PGPORT=17411 PGUSER=postgres PGPASSWORD=zabbix createuser --pwprompt zabbix_user

# drop database
PGHOST=10.133.112.87 PGPORT=17411 PGUSER=postgres PGPASSWORD=zabbix dropdb zabbix_db

# create database 'zabbix_db'
PGHOST=10.133.112.87 PGPORT=17411 PGUSER=postgres PGPASSWORD=zabbix createdb -O zabbix_user zabbix_db

# move to '/tmp' download zabbix source to get stock schema
cd /tmp
curl https://cdn.zabbix.com/zabbix/sources/stable/5.0/zabbix-5.0.5.tar.gz -o zabbix-source.tar.gz
gunzip zabbix-source.tar.gz
tar xvf zabbix-source.tar
rm -rf zabbix-source.tar

# insert stock schema
cat /tmp/zabbix-5.0.5/database/postgresql/schema.sql | PGHOST=10.133.112.87 PGPORT=17411 PGUSER=zabbix_user PGPASSWORD=zabbix psql zabbix_db > /tmp/data.insert.log 2>&1

# check errors
head -10 /tmp/data.insert.log
tail -10 /tmp/data.insert.log
grep -i error /tmp/data.insert.log
grep -i warning /tmp/data.insert.log


# insert data from backup
cat /tmp/data.sql | PGHOST=10.133.112.87 PGPORT=17411 PGPASSWORD=zabbix PGUSER=zabbix_user PGPASSWORD=zabbix psql zabbix_db >> /tmp/data.insert.log 2>&1

# check errors
head -10 /tmp/data.insert.log
tail -20 /tmp/data.insert.log
grep -i error /tmp/data.insert.log
grep -i warning /tmp/data.insert.log






# contact azure instance with most privilaged user 'postgres' and download structure of everything. It will be 2 megabyte file
PGPASSWORD=zabbix \
pg_dumpall \
--host=HOSTNAME \
--port=PORT \
--username=postgres \
--schema-only \
--file=/tmp/azure.postgres.schema.only

# exit 'postgres' user
exit



PGPASSWORD=zabbix \
pg_dumpall \
--host=10.133.112.87 \
--port=7412 \
--username=postgres \
--schema-only \
--file=/tmp/azure.postgres.schema.only



--schema-only > /tmp/all.sql


pg_dump \
--host=10.133.112.87 \
--port=7412 \
--dbname=z44 \
--username=zabbix \
--password \
--format=plain \
--schema-only > /tmp/schema.sql


# cat azure.postgres.schema.only | grep "^CREATE TABLE" | sort | uniq

cat schema.sql | grep "^CREATE TABLE" | sort | uniq

# default approach. must be used under 'postgres' user.
PGPASSWORD=zabbix \
pg_dump \
--username=postgres \
--schema-only \
--dbname=zabbix \
--file=schema.sql

cat schema.sql | grep "^CREATE TABLE" | sort | uniq


# approach 3. is working
PGPASSWORD=zabbix \
pg_dump \
--username=postgres \
--exclude-schema=_timescaledb_internal \
--schema-only \
--dbname=zabbix \
--file=exclude.schema.timescaledb.internal.sql
cat exclude.schema.timescaledb.internal.sql | grep "^CREATE TABLE" | sort | uniq
cat exclude.schema.timescaledb.internal.sql | grep "^CREATE TABLE" | sort | uniq | wc -l
grep "^CREATE TRIGGER" exclude.schema.timescaledb.internal.sql



--see size of table events. this table is next biggest after raw historical data
SELECT pg_size_pretty( pg_total_relation_size('events') );


# download data. seems to be excluding everything timescale related
PGPASSWORD=zabbix \
pg_dump \
--username=postgres \
--exclude-schema=_timescaledb_internal \
--exclude-schema=_timescaledb_cache \
--exclude-schema=_timescaledb_catalog \
--exclude-schema=_timescaledb_config \
--exclude-table-data=history* \
--exclude-table-data=trends* \
--data-only \
--dbname=zabbix \
--file=data.sql


# fetch data from cloud

pg_dump \
--exclude-schema=_timescaledb_internal \
--exclude-schema=_timescaledb_cache \
--exclude-schema=_timescaledb_catalog \
--exclude-schema=_timescaledb_config \
--exclude-table-data=history* \
--exclude-table-data=trends* \
--data-only \
--dbname=z50 \
--file=data.sql


# detete all timescale related triggers
sed -i "s|^CREATE TRIGGER ts_.*$||" exclude.schema.timescaledb.internal.sql




# approach 4
PGPASSWORD=zabbix \
pg_dump \
--username=postgres \
--exclude-schema=_timescaledb_internal \
--schema-only \
--dbname=zabbix \
--file=schema.sql




--exclude-schema=pg_catalog \
--exclude-schema=_timescaledb_catalog \


PGPASSWORD=zabbix \
pg_dump \
--host=10.133.112.87 \
--port=7412 \
--username=postgres \
--exclude-table='_hyper*chunk' \
--schema-only \
--dbname=z50 \
--file=/tmp/azure.postgres.schema.only



PGHOST=10.133.112.87 PGPORT=7412 PGPASSWORD=zabbix PGUSER=postgres \
pg_dump \
--data-only \
--exclude-schema=_timescaledb_internal \
--exclude-schema=_timescaledb_catalog \
--exclude-schema=pg_catalog \
--exclude-table-data=history* \
--exclude-table-data=trends* \
--format=plain \
z50 | gzip --fast > /tmp/data.sql.gz


--exclude-table

--exclude-schema=_timescaledb_internal

exit


# create user
createuser --pwprompt zabbix

dropdb zabbix
# create database 'zabbix' where owner is user 'zabbix'
createdb -O zabbix zabbix

# insert 5.0 schema
cd ~/zabbix-5.0.4/database/postgresql/
cat schema.sql | psql zabbix
# insert sql under bash user zabbix which will be automatically correlated with SQL user 'zabbix' if exists
cat schema.sql | sudo -u zabbix psql zabbix

su - postgres

# create timescaledb extenison. this must be done super user
echo "CREATE EXTENSION IF NOT EXISTS timescaledb CASCADE;" | psql zabbix

# enable timescaledb definition how to chunk data for all 7 historical tables
cat timescaledb.sql | psql zabbix

zcat /usr/share/doc/zabbix-server-pgsql/timescaledb.sql.gz | psql zabbix

cat timescaledb.sql | psql zabbix


# cat images.sql data.sql | psql --port=5432 zabbix

# make sure extension is there
echo "SELECT * FROM pg_extension;" | psql zabbix
# it should report timescaledb at least 1.7.4

# observe hypertables
echo "SELECT * FROM chunk_relation_size_pretty('trends');" | psql zabbix
# it should empty table structure only. no hypertables are made yet


# poll out data from old server. ignore historical data. ignore all hypertables comming from timescaledb
cd
PGHOST=10.133.112.87 PGPORT=7412 PGPASSWORD=zabbix PGUSER=postgres \
pg_dump \
--data-only \
--exclude-schema=_timescaledb_internal \
--exclude-schema=_timescaledb_catalog \
--exclude-schema=pg_catalog \
--exclude-table-data=history* \
--exclude-table-data=trends* \
--format=plain \
z50 | gzip --fast > /tmp/data.sql.gz

# this will print a message per tables 'triggers', 'items', 'httptest', 'hosts', 'group_prototype', 'graphs', 'application_prototype', 'chunk', 'hypertable':
# pg_dump: warning: there are circular foreign-key constraints on this table:
# pg_dump:   httptest
# pg_dump: You might not be able to restore the dump without using --disable-triggers or temporarily dropping the constraints.
# pg_dump: Consider using a full dump instead of a --data-only dump to avoid this problem.


# restore data. dump does not contain hypertables

zcat /tmp/data.sql.gz | sudo -u zabbix psql zabbix


# ERROR:  duplicate key value violates unique constraint "hypertable_pkey"
# DETAIL:  Key (id)=(1) already exists.
# CONTEXT:  COPY hypertable, line 1
# COPY 544
# ERROR:  duplicate key value violates unique constraint "dimension_pkey"
# DETAIL:  Key (id)=(1) already exists.
# CONTEXT:  COPY dimension, line 1







--exclude-table-data='*hypertable*' \
--exclude-table-data='*chunk*' \




PGHOST=10.133.112.87 PGPORT=7412 PGPASSWORD=zabbix PGUSER=postgres \
pg_dump \
--data-only \
--exclude-schema=_timescaledb_internal \
--exclude-table='*history*' \
--exclude-table='*trends*' \
--format=plain \
z50 | gzip --fast > /tmp/data.sql.gz

# dump individual table
PGHOST=10.133.112.87 PGPORT=7412 PGPASSWORD=zabbix PGUSER=postgres \
pg_dump \
--data-only \
--table=history \
--format=plain \
z50 | gzip --fast > /tmp/history.sql.gz

--exclude-table=table









# restore data. dump does not contain hypertables
zcat /tmp/data.sql.gz | psql zabbix


echo "host    all             all             10.133.253.43/32            md5" | sude tee -a /var/lib/pgsql/12/data/pg_hba.conf

systemctl restart postgresql-12

vi /var/lib/pgsql/12/data/pg_hba.conf


--Create traditional trend tables as the old definitions with different names.
CREATE TABLE history_uint_new (LIKE history_uint INCLUDING ALL);

--Then you can migrate old data into new one if needed. This is optional.
--Be sure that you have enough storage to duplicate the tables.
insert into history_uint_new select * from history_uint;

--Be sure that, new tables has the right data. Check the counts.
select count(itemid) from history_uint;
select count(itemid) from history_uint_new;

--Now you can drop old timescaled tables.
drop table history_uint;

--Lastly, rename new traditional tables as needed.
alter table history_uint_new rename to history_uint;


# https://docs.timescale.com/latest/using-timescaledb/backup

