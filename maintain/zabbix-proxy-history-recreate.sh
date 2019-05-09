# ============== TEST FUNCTIONALITY ================

# authorize in mysql client
mysql -uzabbix -p zabbix_proxy

# test 'create table like' function. test 'rename table' function
create table proxy_history_this_is_test like proxy_history; rename table proxy_history_this_is_test to proxy_history_another;

# compare structure for both tables
show create table proxy_history\G; show create table proxy_history_another\G;

# compare size
SELECT table_name, table_rows, data_length, index_length, round(((data_length + index_length) / 1024 / 1024),2) "Size in MB" FROM information_schema.tables WHERE table_schema = "zabbix_proxy" and table_name = "proxy_history" order by round(((data_length + index_length) / 1024 / 1024),2);
SELECT table_name, table_rows, data_length, index_length, round(((data_length + index_length) / 1024 / 1024),2) "Size in MB" FROM information_schema.tables WHERE table_schema = "zabbix_proxy" and table_name = "proxy_history_another" order by round(((data_length + index_length) / 1024 / 1024),2);

# test 'drop table' function
drop table proxy_history_another;

# ============== PRODUCTION ================

# rename existing table and create a new one with the very same structure
rename table proxy_history to proxy_history_old; create table proxy_history like proxy_history_old;
# you will trop some metrics for a second or something

# compare booth tables
show create table proxy_history\G; show create table proxy_history_old\G;

# compare size
SELECT table_name, table_rows, data_length, index_length, round(((data_length + index_length) / 1024 / 1024),2) "Size in MB" FROM information_schema.tables WHERE table_schema = "zabbix_proxy" and table_name = "proxy_history" order by round(((data_length + index_length) / 1024 / 1024),2);
SELECT table_name, table_rows, data_length, index_length, round(((data_length + index_length) / 1024 / 1024),2) "Size in MB" FROM information_schema.tables WHERE table_schema = "zabbix_proxy" and table_name = "proxy_history_old" order by round(((data_length + index_length) / 1024 / 1024),2);

# exit databse client
exit

# use remote host to poll out metrics from "old" table. compress the dump a little
time mysqldump --no-create-info -uzabbix -p zabbix_proxy proxy_history_old | sed "s/proxy_history_old/proxy_history/" | gzip --fast > ~/proxy_history_old.sql.gz

# check if the size of backup is meaningfull
ls -lh ~/proxy_history_old.sql.gz

# take a look at the backup if the substitution went well
zcat ~/proxy_history_old.sql.gz
zcat ~/proxy_history_old.sql.gz | grep -i "insert into" | tail -1 | cut -c 1-50
# notice the line starts with [INSERT INTO `proxy_history` VALUES] so the substitution went well and backup will be restored to right table

# authorize in mysql client
mysql -uzabbix -p zabbix_proxy

# drop old table
drop table proxy_history_old;

# exit mysql client
exit

# insert back proxy_history to live instance
zcat ~/proxy_history_old.sql.gz | mysql -uzabbix -p zabbix_proxy

# sign back in mysql
mysql -uzabbix -p zabbix_proxy
# compare tables

# observe some records in place 
select * from proxy_history order by clock asc limit 10;
select * from proxy_history order by clock desc limit 10; 

exit


