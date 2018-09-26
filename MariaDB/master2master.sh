
# move to super user


# update system
yum -y update && yum -y upgrade

# setup some conveniences
yum -y install vim

# add mariadb repo
https://downloads.mariadb.org/mariadb/repositories/#mirror=netinch&distro=CentOS&distro_release=centos7-amd64--centos7&version=10.2

vim /etc/yum.repos.d/MariaDB.repo
# paste:
# MariaDB 10.2 CentOS repository list - created 2018-08-13 06:39 UTC
# http://downloads.mariadb.org/mariadb/repositories/
[mariadb]
name = MariaDB
baseurl = http://yum.mariadb.org/10.2/centos7-amd64
gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
gpgcheck=1

# generate cache
yum makecache

# install mariadb server
yum install MariaDB-server MariaDB-client

# During installation process MariaDB package will configure initial database and create redo log files with default file size. Remove these files: 
rm -rf /var/lib/mysql/ib_logfile*

cat /etc/my.cnf.d/server.cnf
#
# These groups are read by MariaDB server.
# Use it for options that only the server (but not clients) should see
#
# See the examples of server my.cnf files in /usr/share/mysql/
#

# this is read by the standalone daemon and embedded servers
[server]

# this is only for the mysqld standalone daemon
[mysqld]
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

innodb_buffer_pool_size = 64G
innodb_log_file_size = 4G
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
innodb_support_xa = 0
innodb_thread_concurrency = 0

innodb_purge_threads = 4

gtid_domain_id = 1
server_id = <unique server id>
binlog_checksum = crc32

innodb_lru_scan_depth = 512

innodb_stats_on_metadata = 0
innodb_stats_sample_pages = 32

#
# * Galera-related settings
#
[galera]
# Mandatory settings
#wsrep_on=ON
#wsrep_provider=
#wsrep_cluster_address=
#binlog_format=row
#default_storage_engine=InnoDB
#innodb_autoinc_lock_mode=2
#
# Allow server to accept connections on all interfaces.
#
#bind-address=0.0.0.0
#
# Optional setting
#wsrep_slave_threads=1
#innodb_flush_log_at_trx_commit=0

# this is only for embedded server
[embedded]

# This group is only read by MariaDB servers, not by MySQL.
# If you use the same .cnf file for MySQL and MariaDB,
# you can put MariaDB-only options here
[mariadb]

# This group is only read by MariaDB-10.2 servers.
# If you use the same .cnf file for MariaDB of different versions,
# use this group for options that older servers don't understand
[mariadb-10.2]



