#!/bin/bash
# https://www.a2hosting.com/kb/developer-corner/mysql/convert-mysql-database-utf-8

# install passwordless access for current user
cat <<'EOF' > ~/.my.cnf
[client]
user=zabbix
password="zabbix"
EOF

# test if the connection works
mysql zabbix

# set the right charset and collation
mysql --database=zabbix -B -N -e "SHOW TABLES" | awk '{print "SET foreign_key_checks = 0; ALTER TABLE", $1, "CONVERT TO CHARACTER SET utf8 COLLATE utf8_bin; SET foreign_key_checks = 1; "}' | mysql --database=zabbix
mysql --database=zabbix -B -N -e "ALTER DATABASE zabbix CHARACTER SET utf8 COLLATE utf8_bin;"

# remove credentials file
rm ~/.my.cnf

# set the wrong collation
mysql --database=zabbix -B -N -e "SHOW TABLES" | awk '{print "SET foreign_key_checks = 0; ALTER TABLE", $1, "CONVERT TO CHARACTER SET latin1; SET foreign_key_checks = 1; "}' | mysql --database=zabbix
mysql --database=zabbix -B -N -e "ALTER DATABASE zabbix CHARACTER SET latin1;"


# APPENDINX. MANUALLY TEST in client on one table
# mysql> SET foreign_key_checks = 0; ALTER TABLE widget_field CONVERT TO CHARACTER SET utf8 COLLATE utf8_bin; SET foreign_key_checks = 1; 




