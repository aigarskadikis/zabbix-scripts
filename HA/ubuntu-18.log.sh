
10.1.10.5 node1
10.1.10.6 node2

# execute on node 1
sudo hostnamectl set-hostname node1
echo 127.0.0.1 node1|sudo tee -a /etc/hosts
echo 10.1.10.5 node1|sudo tee -a /etc/hosts
echo 10.1.10.6 node2|sudo tee -a /etc/hosts

# execute on node 2
sudo hostnamectl set-hostname node2
echo 127.0.0.1 node2|sudo tee -a /etc/hosts
echo 10.1.10.5 node1|sudo tee -a /etc/hosts
echo 10.1.10.6 node2|sudo tee -a /etc/hosts

sudo apt -y update
sudo apt -y upgrade

sudo apt -y install ntp
sudo systemctl enable ntp
sudo systemctl start ntp
sudo systemctl status ntp

# install timezone
sudo cp /usr/share/zoneinfo/Europe/Riga /etc/localtime
# check date now
date


# https://downloads.mariadb.org/mariadb/repositories/#mirror=digitalocean-nyc&version=10.3
sudo apt-get install software-properties-common
sudo apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xF1656F24C74CD1D8
sudo add-apt-repository 'deb [arch=amd64,arm64,ppc64el] http://nyc2.mirrors.digitalocean.com/mariadb/repo/10.3/ubuntu bionic main'

sudo apt -y update
sudo apt -y install mariadb-server mariadb-client

# install tuning on node1
systemctl stop mariadb
systemctl status mariadb

rm -rf /var/lib/mysql/ib_logfile*

cd /etc/mysql/mariadb.conf.d
cat << 'EOF' > server.cnf
[mysqld]
bind-address = 0.0.0.0
user = mysql
local_infile = 0
symbolic_links = 0

default-storage-engine = InnoDB
skip-name-resolve
key_buffer_size = 32M
max_allowed_packet = 128M
table_open_cache = 1024
table_definition_cache = 1024
max_connections = 2000
join_buffer_size = 1M
sort_buffer_size = 2M
read_buffer_size = 256K
read_rnd_buffer_size = 256K
myisam_sort_buffer_size = 1M
thread_cache_size = 512
query_cache_type = 0
open_files_limit = 65535
wait_timeout = 86400

optimizer_switch=index_condition_pushdown=off

tmp_table_size = 64M
max_heap_table_size = 64M

binlog_format=mixed
binlog_cache_size = 64M
max_binlog_size = 1G
expire_logs_days = 3

innodb_buffer_pool_size = 512M
innodb_log_file_size = 90M
innodb_log_buffer_size = 128M
innodb_file_per_table = 1
innodb_flush_method = O_DIRECT
innodb_buffer_pool_instances = 8
innodb_write_io_threads = 8
innodb_read_io_threads = 8
innodb_adaptive_flushing = 1
innodb_lock_wait_timeout = 50

innodb_flush_log_at_trx_commit = 2

innodb_io_capacity = 2000
innodb_io_capacity_max = 2500
innodb_flush_neighbors = 0

innodb_checksums = 1
innodb_doublewrite = 1
innodb_thread_concurrency = 0

innodb_purge_threads = 4

large-pages

gtid_domain_id = 1
server_id = 1
binlog_checksum = crc32

innodb_lru_scan_depth = 512

innodb_stats_on_metadata = 0
innodb_stats_sample_pages = 32
EOF


systemctl start mariadb
netstat -an | grep 3306

mysql <<< 'show variables like "server_id";'


# ============== ON NODE2 =============

# install tuning on node2
systemctl stop mariadb
rm -rf /var/lib/mysql/ib_logfile*

cd /etc/mysql/mariadb.conf.d
cat << 'EOF' > server.cnf
[mysqld]
bind-address = 0.0.0.0
user = mysql
local_infile = 0
symbolic_links = 0

default-storage-engine = InnoDB
skip-name-resolve
key_buffer_size = 32M
max_allowed_packet = 128M
table_open_cache = 1024
table_definition_cache = 1024
max_connections = 2000
join_buffer_size = 1M
sort_buffer_size = 2M
read_buffer_size = 256K
read_rnd_buffer_size = 256K
myisam_sort_buffer_size = 1M
thread_cache_size = 512
query_cache_type = 0
open_files_limit = 65535
wait_timeout = 86400

optimizer_switch=index_condition_pushdown=off

tmp_table_size = 64M
max_heap_table_size = 64M

binlog_format=mixed
binlog_cache_size = 64M
max_binlog_size = 1G
expire_logs_days = 3

innodb_buffer_pool_size = 512M
innodb_log_file_size = 90M
innodb_log_buffer_size = 128M
innodb_file_per_table = 1
innodb_flush_method = O_DIRECT
innodb_buffer_pool_instances = 8
innodb_write_io_threads = 8
innodb_read_io_threads = 8
innodb_adaptive_flushing = 1
innodb_lock_wait_timeout = 50

innodb_flush_log_at_trx_commit = 2

innodb_io_capacity = 2000
innodb_io_capacity_max = 2500
innodb_flush_neighbors = 0

innodb_checksums = 1
innodb_doublewrite = 1
innodb_thread_concurrency = 0

innodb_purge_threads = 4

large-pages

gtid_domain_id = 1
server_id = 2
binlog_checksum = crc32

innodb_lru_scan_depth = 512

innodb_stats_on_metadata = 0
innodb_stats_sample_pages = 32
EOF

systemctl start mariadb
netstat -an | grep 3306

mysql <<< 'show variables like "server_id";'



# ==== ON NODE1 =======

mysql <<< 'FLUSH TABLES WITH READ LOCK;'


# create a backup of node1
cd /home/vagrant

mysqldump --master-data --gtid --all-databases > backup.sql

# ==== ON NODE2 =======
# try if node2 can connect to node1
mysql -h 10.1.10.5 -P 3306 -ureplicator -preplicator
# it should NOT work!

# ==== ON NODE1 =======
# run on node1. allow 10.1.10.6 to connect on 10.1.10.5
mysql <<< 'GRANT REPLICATION SLAVE ON *.* TO "replicator"@"10.1.10.6" identified by "replicator"; GRANT REPLICATION SLAVE ON *.* TO "replicator"@"node2" identified by "replicator"; FLUSH PRIVILEGES;'

# ==== ON NODE2 =======
# try if node2 can connect to node1
mysql -h 10.1.10.5 -P 3306 -ureplicator -preplicator

# ==== ON NODE2 =======
# Recover MySQL dump to the slave MySQL server
cd /home/vagrant
cat backup.sql | mysql

# ==== ON NODE2 =======
mysql <<< 'show slave status\G;'
mysql <<< 'STOP SLAVE;'
mysql <<< 'CHANGE MASTER TO master_host="10.1.10.5", master_port=3306, master_user="replicator", master_password="replicator", master_use_gtid=slave_pos;'
mysql <<< 'START SLAVE;'
mysql <<< 'show slave status\G;'

# ==== ON NODE1 =======
# try if node1 can connect to node2
mysql -h 10.1.10.6 -P 3306 -ureplicator -preplicator
# it should NOT work

# ==== ON NODE2 =======
# run on node2. allow 10.1.10.5 to connect on 10.1.10.6
mysql <<< 'GRANT REPLICATION SLAVE ON *.* TO "replicator"@"10.1.10.5" identified by "replicator"; GRANT REPLICATION SLAVE ON *.* TO "replicator"@"node1" identified by "replicator"; FLUSH PRIVILEGES;'

# ==== ON NODE1 =======
mysql <<< 'show slave status\G;'
mysql <<< 'STOP SLAVE;'
mysql <<< 'CHANGE MASTER TO master_host="10.1.10.6", master_port=3306, master_user="replicator", master_password="replicator", master_use_gtid=slave_pos;'
mysql <<< 'start slave;'
mysql <<< 'show slave status\G;'
mysql <<< 'UNLOCK TABLES;'




