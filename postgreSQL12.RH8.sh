

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

systemctl enable postgresql-12
systemctl start postgresql-12
systemctl status postgresql-12


# navigate to posgres user (root for db engine)
su - postgres




cd
curl https://cdn.zabbix.com/zabbix/sources/stable/5.0/zabbix-5.0.4.tar.gz -o zabbix-source.tar.gz
gunzip zabbix-source.tar.gz
tar xvf zabbix-source.tar
rm -rf zabbix-source.tar
cd zabbix-5.0.4/database/postgresql/


# create user
createuser --pwprompt zabbix

dropdb zabbix
# create database 'zabbix' where owner is user 'zabbix'
createdb -O zabbix zabbix

# insert 5.0 schema
cd ~/zabbix-5.0.4/database/postgresql/
cat schema.sql | psql --port=5432 zabbix

# create timescaledb extenison
echo "CREATE EXTENSION IF NOT EXISTS timescaledb CASCADE;" | psql zabbix

# enable timescaledb definition how to chunk data for all 7 historical tables
cat timescaledb.sql | psql --port=5432 zabbix


# cat images.sql data.sql | psql --port=5432 zabbix

# make sure extension is there
echo "SELECT * FROM pg_extension;" | psql zabbix
# it should report timescaledb at least 1.7.4

# observe hypertables
echo "SELECT * FROM chunk_relation_size_pretty('trends');" | psql zabbix
# it should empty table structure only. no hypertables are made yet


# poll backup data from old server. without history
cd
PGHOST=10.133.112.87 PGPORT=7412 PGPASSWORD=zabbix PGUSER=postgres \
pg_dump \
--data-only \
--exclude-schema=_timescaledb_internal \
--exclude-table-data=history* \
--exclude-table-data=trends* \
--format=plain \
z50 | gzip > data.sql.gz

# restore data. dump does not contain hypertables
zcat data.sql.gz | psql zabbix


# https://docs.timescale.com/latest/using-timescaledb/backup

