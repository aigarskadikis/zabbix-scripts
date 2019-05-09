# ============== TEST FUNCTIONALITY ================

# authorize in mysql client
mysql -uzabbix -p zabbix

# test 'create table like' function. test 'rename table' function
create table trends_this_is_test like trends; rename table trends_this_is_test to trends_another;

# compare structure for both tables
show create table trends\G; show create table trends_another\G;

# compare size
SELECT table_name, table_rows, data_length, index_length, round(((data_length + index_length) / 1024 / 1024),2) "Size in MB" FROM information_schema.tables WHERE table_schema = "zabbix" and table_name = "trends" order by round(((data_length + index_length) / 1024 / 1024),2);
SELECT table_name, table_rows, data_length, index_length, round(((data_length + index_length) / 1024 / 1024),2) "Size in MB" FROM information_schema.tables WHERE table_schema = "zabbix" and table_name = "trends_another" order by round(((data_length + index_length) / 1024 / 1024),2);

# test 'drop table' function
drop table trends_another;

# ============== PRODUCTION ================

# rename existing table and create a new one with the very same structure
rename table trends to trends_old; create table trends like trends_old;
# you will trop some metrics for a second or something

# compare booth tables
show create table trends\G; show create table trends_old\G;

# compare size
SELECT table_name, table_rows, data_length, index_length, round(((data_length + index_length) / 1024 / 1024),2) "Size in MB" FROM information_schema.tables WHERE table_schema = "zabbix" and table_name = "trends" order by round(((data_length + index_length) / 1024 / 1024),2);
SELECT table_name, table_rows, data_length, index_length, round(((data_length + index_length) / 1024 / 1024),2) "Size in MB" FROM information_schema.tables WHERE table_schema = "zabbix" and table_name = "trends_old" order by round(((data_length + index_length) / 1024 / 1024),2);

# exit databse client
exit

# use remote host to poll out metrics from "old" table. compress the dump a little
time mysqldump --no-create-info -uzabbix -p zabbix trends_old | sed "s/trends_old/trends/" | gzip --fast > ~/trends_old.sql.gz

# check if the size of backup is meaningfull
ls -lh ~/trends_old.sql.gz

# take a look at the backup if the substitution went well
zcat ~/trends_old.sql.gz | grep -i "insert into" | tail -1 | cut -c 1-50
# notice the line starts with [INSERT INTO `trends` VALUES] so the substitution went well and backup will be restored to right table

# authorize in mysql client
mysql -uzabbix -p zabbix

# drop old table
drop table trends_old;

# exit mysql client

# insert trends back to live instance
zcat ~/trends_old.sql.gz | mysql -uzabbix -p zabbix

# sign back in mysql
mysql -uzabbix -p zabbix
# compare tables

# observe some records in place 
select * from trends order by clock asc limit 10;
select * from trends order by clock desc limit 10; 

exit


