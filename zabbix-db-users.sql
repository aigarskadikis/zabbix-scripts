
--for MySQL 8
--generate rendom password from bash
-- < /dev/urandom tr -dc A-Za-z0-9 | head -c${1:-20};echo;


CREATE USER   
'zbx_srv'@'192.168.88.101' IDENTIFIED WITH mysql_native_password BY 'pass_zbx_srv',   
'zbx_srv'@'192.168.88.102' IDENTIFIED WITH mysql_native_password BY 'pass_zbx_srv',   
'zbx_web'@'192.168.88.103' IDENTIFIED WITH mysql_native_password BY 'pass_zbx_web',
'zbx_web'@'192.168.88.104' IDENTIFIED WITH mysql_native_password BY 'pass_zbx_web',
'zbx_part'@'127.0.0.1' IDENTIFIED WITH mysql_native_password BY 'pass_zbx_part',
'zbx_monitor'@'127.0.0.1' IDENTIFIED WITH mysql_native_password BY 'pass_zbx_monitor';

CREATE ROLE 'zbx_srv_role', 'zbx_web_role';

GRANT SELECT, UPDATE, DELETE, INSERT, CREATE, DROP, ALTER, INDEX, REFERENCES ON zabbix.* TO 'zbx_srv_role';

GRANT SELECT, UPDATE, DELETE, INSERT ON zabbix.* TO 'zbx_web_role';

GRANT ALL PRIVILEGES ON *.* to 'zbx_part'@'127.0.0.1';

GRANT REPLICATION CLIENT,PROCESS,SHOW DATABASES,SHOW VIEW ON *.* TO 'zbx_monitor'@'127.0.0.1';


GRANT 'zbx_srv_role' TO 'zbx_srv'@'192.168.88.101';
GRANT 'zbx_srv_role' TO 'zbx_srv'@'192.168.88.102';
GRANT 'zbx_web_role' TO 'zbx_web'@'192.168.88.103';
GRANT 'zbx_web_role' TO 'zbx_web'@'192.168.88.104';

SET DEFAULT ROLE 'zbx_srv_role' TO 'zbx_srv'@'192.168.88.101';
SET DEFAULT ROLE 'zbx_srv_role' TO 'zbx_srv'@'192.168.88.102';
SET DEFAULT ROLE 'zbx_web_role' TO 'zbx_web'@'192.168.88.103';
SET DEFAULT ROLE 'zbx_web_role' TO 'zbx_web'@'192.168.88.104';


