   server_a (192.168.0.12) 
   server_b (192.168.0.15)

====configuring server_a====
vi /etc/my.cnf
[mysqld]
log-bin
server_id=1
replicate-do-db=replicate
bind-address=192.168.0.12


systemctl restart mariadb

CREATE USER '$master_username'@'%' IDENTIFIED BY '$master_password';

GRANT REPLICATION SLAVE ON *.* TO '$master_username'@'%';
FLUSH PRIVILEGES;
SHOW MASTER STATUS;


====configuring server_b====
vi /etc/my.cnf
[mysqld]
log-bin
server_id=2
replicate-do-db=replicate
bind-address=192.168.0.15

systemctl restart mariadb

