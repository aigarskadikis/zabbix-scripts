
# make sure the user is 'root'
whoami



# create a source folder
mkdir ~/zabbix-source

# goto source
cd ~/zabbix-source

# take backup 3 days ago
find /home/zbxbackupuser/zabbix_backup -newermt "2020-02-19" ! -newermt '2020-02-20'


find /home/zbxbackupuser/zabbix_backup -newermt "2020-02-19" ! -newermt '2020-02-20' | grep tar\.gz | head -1

# cp sql to current dir
find /home/zbxbackupuser/zabbix_backup -newermt "2020-02-19" ! -newermt '2020-02-20' | grep db.conf.*.gz | head -1

# unpack content to current dir
tar -vzxf $(find /home/zbxbackupuser/zabbix_backup -newermt "2020-02-19" ! -newermt '2020-02-20' | grep tar\.gz | head -1)

# take sql
cp $(find /home/zbxbackupuser/zabbix_backup -newermt "2020-02-19" ! -newermt '2020-02-20' | grep db.conf.*.gz | head -1) .

# make sure backend is down
systemctl stop zabbix-server zabbix-agent

# ensure no zabbix processes is running
ps -ef | grep "[z]abbix"

# overwrite some files from backup
cat etc/zabbix/zabbix_server.conf > /etc/zabbix/zabbix_server.conf
cat etc/zabbix/zabbix_agent2.conf > /etc/zabbix/zabbix_agent2.conf



# stop database server
systemctl stop mariadb

# remove database content
rm -rf /var/lib/mysql/*

# start database server
systemctl start mariadb
