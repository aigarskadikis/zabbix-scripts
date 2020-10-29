# https://www.postgresql.org/download/linux/redhat/
# https://pgloader.readthedocs.io/en/latest/
# https://centos.pkgs.org/8/raven-x86_64/pgloader-3.6.2-1.el8.x86_64.rpm.html
# https://docs.timescale.com/latest/getting-started/installation/rhel-centos/installation-yum
 
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
 
# Disable built-in PostgreSQL module:
dnf -qy module disable postgresql
 
# Install PostgreSQL, TimescaleDB extension. pgloader requires openssl-devel
dnf -y install postgresql12-server timescaledb-postgresql-12 openssl-devel nmap vim
 
# allow connect to database from 127.0.0.1
vi /var/lib/pgsql/12/data/pg_hba.conf
# replace:
host all all 127.0.0.1/32 ident
# with:
host all all 127.0.0.1/32 md5
 
if another host needs to access this machine then whitelist the address:
echo "host all all 10.133.253.43/32 md5" | sudo tee -a /var/lib/pgsql/12/data/pg_hba.conf
 
# enable TimescaleDB module
echo "shared_preload_libraries = 'timescaledb'" >> /var/lib/pgsql/12/data/postgresql.conf
 
# observe current listening address
grep listen_addresses /var/lib/pgsql/12/data/postgresql.conf
 
# initialize database and enable automatic start:
/usr/pgsql-12/bin/postgresql-12-setup initdb
systemctl enable postgresql-12
systemctl start postgresql-12
 
# create new postgres database user 'zabbix', password will be prompted
sudo -u postgres createuser --pwprompt zabbix
sudo -u postgres createdb -O zabbix zabbix
 
# a dependency for pgloader
dnf -y install openssl-devel
 
# install pgloader
rpm -ivh https://pkgs.dyn.su/el8/base/x86_64/pgloader-3.6.2-1.el8.x86_64.rpm
 
# download 5.0 source
cd &&  curl -s "https://cdn.zabbix.com/zabbix/sources/stable/5.0/zabbix-5.0.5.tar.gz" -o zabbix-source.tar.gz && ls -lh zabbix-source.tar.gz
 
# unpack archive
gunzip zabbix-source.tar.gz && tar xvf zabbix-source.tar
 
# for the migration we must configure to allow inserting data in postgres database without respecting contraints
cd ~/zabbix-5.0.5/database/postgresql
sed -n '/CREATE.*/,/INSERT.*$/p' schema.sql | head -n-1 > ~/create.sql
grep ALTER schema.sql > ~/alter.sql
 
# create pgloader migration profile
cd
cat << 'EOF' > pgloader.conf
LOAD DATABASE
FROM mysql://zabbix:zabbix@127.0.0.1:3306/zabbix
INTO postgresql://zabbix:zabbix@127.0.0.1:5432/zabbix
WITH include no drop,
truncate,
create no tables,
create no indexes,
no foreign keys,
reset sequences,
data only
SET maintenance_work_mem TO '1024MB', work_mem to '256MB'
ALTER SCHEMA 'zabbix' RENAME TO 'public'
BEFORE LOAD EXECUTE create.sql
AFTER LOAD EXECUTE alter.sql;
EOF
 
# test dry run
pgloader --dry-run pgloader.conf
# by default it generates information on screen and plus writes a log file '/tmp/pgloader/pgloader.log'
 
# a successfull output looks like. 'Success' in 2 places:
# pgloader --dry-run pgloader.conf
# 2020-10-01T18:59:51.016000+06:00 LOG pgloader version "3.6.2"
# 2020-10-01T18:59:51.081000+06:00 LOG DRY RUN, only checking connections.
# 2020-10-01T18:59:51.082000+06:00 LOG Attempting to connect to #<MYSQL-CONNECTION mysql://zabbix@10.133.80.228:10317/zabbix {100603A0F3}>
# 2020-10-01T18:59:51.158000+06:00 LOG Success, opened #<MYSQL-CONNECTION mysql://zabbix@10.133.80.228:10317/zabbix {100603A0F3}>.
# 2020-10-01T18:59:51.159000+06:00 LOG Running a simple query: SELECT 1;
# 2020-10-01T18:59:51.172000+06:00 LOG Attempting to connect to #<PGSQL-CONNECTION pgsql://zabbix@localhost:5432/zabbix {100603B703}>
# 2020-10-01T18:59:51.226000+06:00 LOG Success, opened #<PGSQL-CONNECTION pgsql://zabbix@localhost:5432/zabbix {100603B703}>.
# 2020-10-01T18:59:51.226000+06:00 LOG Running a simple query: SELECT 1;
# 2020-10-01T18:59:51.229000+06:00 LOG report summary reset
# table name errors rows bytes total time
# ----------------- --------- --------- --------- --------------
# ----------------- --------- --------- --------- --------------
 
# install screens utility
dnf install epel-release && dnf install screen
 
# enter 'screen' mode
screen
 
# execute migration
pgloader pgloader.conf
# by default it writes a log file at '/tmp/pgloader/pgloader.log'
 
grep WARNING /tmp/pgloader/pgloader.log
grep ERROR /tmp/pgloader/pgloader.log
 
# create timescale extension
echo "CREATE EXTENSION IF NOT EXISTS timescaledb CASCADE;" | sudo -u postgres psql zabbix
cp ~/zabbix-5.0.5/database/postgresql/timescaledb.sql /tmp
 
su - postgres
 
# test connection from postgres user 'zabbix'
psql --host=127.0.0.1 --username=zabbix zabbix
\d
\q
 
# apply timescale extension
cat /tmp/timescaledb.sql | psql --host=127.0.0.1 --username=zabbix zabbix
