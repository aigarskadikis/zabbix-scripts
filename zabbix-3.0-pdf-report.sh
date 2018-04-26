#!/bin/bash

#check current SELinux status
getenforce

#turn of SELinux
setenforce 0

#install git and vim
yum install git vim -y

#look where is zabbix front end directory
find / -name trigger_prototypes.php

#move to the frontend dir
cd /usr/share/zabbix/

#download code
git clone https://github.com/kmpm/zabbix-dynamic-pdf-report.git

#rename directory to 'report'
mv zabbix-dynamic-pdf-report report

#move to dir
cd report

#make temp dir and dir for reports. assign permissions that everyone can write to it
mkdir tmp reports
chmod -R 777 tmp reports

#Unable to login: Array ( [code] => -32602 [message] => Invalid params. [data] => Incorrect method "user.authenticate". )
sed -i "s/user.authenticate/user.login/g" inc/ZabbixAPI.class.php

#clone default conf
cp config.inc.sample.php config.inc.php

#enter credentials
vim config.inc.php
#$z_server       = 'http://192.168.3.246/zabbix/';
#$z_user         = 'Admin';
#$z_pass         = 'zabbix';

#go to
http://192.168.3.246/zabbix/report
