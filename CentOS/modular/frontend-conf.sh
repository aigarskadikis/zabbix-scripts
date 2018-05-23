#!/bin/bash

#configure timezone
sed -i "s/^.*php_value date.timezone .*$/php_value date.timezone Europe\/Riga/" /etc/httpd/conf.d/zabbix.conf

#configure zabbix to host on root
grep "^Alias" /etc/httpd/conf.d/zabbix.conf
if [ $? -ne 0 ]; then
echo Alias not found in "/etc/httpd/conf.d/zabbix.conf". Something is out of order.
else
#replace one line:
#Alias /zabbix /usr/share/zabbix-agent
#with two lines
#<VirtualHost *:80>
#DocumentRoot /usr/share/zabbix
sed -i "s/Alias \/zabbix \/usr\/share\/zabbix/<VirtualHost \*:80>\nDocumentRoot \/usr\/share\/zabbix/" /etc/httpd/conf.d/zabbix.conf

#add to the end of the file:
#</VirtualHost>
grep "</VirtualHost>" /etc/httpd/conf.d/zabbix.conf
if [ $? -eq 0 ]; then
echo "</VirtualHost>" already exists in the file /etc/httpd/conf.d/zabbix.conf
else
echo "</VirtualHost>" >> /etc/httpd/conf.d/zabbix.conf
fi

sed -i "s/^/#/g" /etc/httpd/conf.d/welcome.conf

cat > /etc/zabbix/web/zabbix.conf.php << EOF
<?php
// Zabbix GUI configuration file.
global \$DB;

\$DB['TYPE']     = 'MYSQL';
\$DB['SERVER']   = 'localhost';
\$DB['PORT']     = '0';
\$DB['DATABASE'] = 'zabbix';
\$DB['USER']     = 'zabbix';
\$DB['PASSWORD'] = 'TaL2gPU5U9FcCU2u';

// Schema name. Used for IBM DB2 and PostgreSQL.
\$DB['SCHEMA'] = '';

\$ZBX_SERVER      = 'localhost';
\$ZBX_SERVER_PORT = '10051';
\$ZBX_SERVER_NAME = '$1';

\$IMAGE_FORMAT_DEFAULT = IMAGE_FORMAT_PNG;
EOF

systemctl restart httpd
systemctl enable httpd
