# ============== TEST FUNCTIONALITY ================

# authorize in mysql client
mysql -uzabbix -p zabbix_proxy

# test 'create table like' function. test 'rename table' function
create table proxy_history_this_is_test like proxy_history; rename table proxy_history_this_is_test to proxy_history_another;

# compare structure for both tables
show create table proxy_history\G; show create table proxy_history_another\G;

# test 'drop table' function
drop table proxy_history_another;

# ============== PRODUCTION ================

# rename existing table and create a new one with the very same structure
rename table proxy_history to proxy_history_old; create table proxy_history like proxy_history_old;

# compare both tables
show create table proxy_history\G; show create table proxy_history_old\G;

# exit databse client
exit

# use remote host to poll out metrics from "old" table. compress the dump a little
time mysqldump --no-create-info -uzabbix -p zabbix_proxy proxy_history_old | gzip --fast > ~/proxy_history_old.sql.gz

# check if the size of backup is meaningful
ls -lh ~/proxy_history_old.sql.gz

# authorize in mysql client
mysql -uzabbix -p zabbix_proxy

# drop old table
drop table proxy_history_old;

# exit mysql client
exit

# using remote host insert back proxy_history to live instance
zcat ~/proxy_history_old.sql.gz | sed "s/proxy_history_old/proxy_history/" | mysql -uzabbix -p zabbix_proxy

# sign back in mysql
mysql -uzabbix -p zabbix_proxy

# observe some records in place 
select * from proxy_history order by clock asc limit 10;
select * from proxy_history order by clock desc limit 10; 

exit
