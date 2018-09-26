
#install ssh key
mkdir -p ~/.ssh && echo "ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAQEAqkmrGeulxpX2NWr5cMUndl+wemjatXp5CSkxUna1Es0vqmkEn+ujA39RSqFB7Vvfl2R+ddOUW9JSC6VXc6CYMyVhYd/0KGg8YkD6ZTKK5zKhj34UQ/mhGptcnwXjpDyjQ6vAV2gb5YAceNHvRYx1M171LhbSlogxqBQGcD31XgG3fVXcw7spjAILBh4QUBQt6vD28Bq/W8jA91mvgov/ZW0dDA0sJDR5BvsUEQRJYAt7yy93uhV3bkI1jO6463ra5eMZHPPmmKwYhon5spCvomqWgh9lB/zpy33R9VuJsGJ9fJ/AL3RKROEMa+wtuGcs5NmStjS+kMbaIzAFIvn5Ow== rsa-key-20180524"> ~/.ssh/authorized_keys && chmod -R 700 ~/.ssh

#enter zabbix database in a safe way
mysql -u$(grep "^DBUser" /etc/zabbix/zabbix_server.conf|sed "s/^.*=//") -p$(grep "^DBPassword" /etc/zabbix/zabbix_server.conf|sed "s/^.*=//")

# browse sqlite database
sqlite3 /dev/shm/zabbix.db.sqlite3

#open udp 162 port
systemctl enable firewalld && systemctl start firewalld && firewall-cmd --add-port=162/udp --permanent && firewall-cmd --reload
systemctl enable firewalld && systemctl start firewalld && firewall-cmd --add-port=161/udp --permanent && firewall-cmd --reload

#install snmpd
yum -y install net-snmp net-snmp-utils && systemctl enable snmpd && systemctl start snmpd


vi /etc/snmp/snmpd.conf

systemctl restart snmpd


exec .1.3.6.1.4.1.2021.51 ps /bin/ps

systemctl restart snmpd
snmpwalk -v2c -cpublic localhost 1.3.6.1.2.1.1.6.0
SNMPv2-MIB::sysLocation.0 = STRING: Unknown (edit /etc/snmp/snmpd.conf)

syslocation