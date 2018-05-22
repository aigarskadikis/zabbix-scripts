#this is one of best practice tip regarding to zabbix frontend setup

#generate some random password
pw=$(< /dev/urandom tr -dc '12345!@#$%qwertQWERTasdfgASDFGzxcvbZXCVB' | head -c10; echo "") && echo $pw

#authorize in MySQL
mysql -h localhost -uroot -p5sRj4GXspvDKsBXW -P 3306

#create new user
GRANT SELECT, UPDATE, DELETE, INSERT ON zabbix.* TO 'zabbix_web'@'localhost' identified by 'c$2Q!V4S%R';

#show grants for this user
SHOW GRANTS FOR 'zabbix_web'@'localhost';

exit

vi /etc/zabbix/web/zabbix.conf.php

#modify /etc/zabbix/web/zabbix.conf.php to look like
#$DB['DATABASE'] = 'zabbix';
#$DB['USER']     = 'zabbix_web';
#$DB['PASSWORD'] = 'c$2Q!V4S%R';

#restart web server
systemctl restart httpd

