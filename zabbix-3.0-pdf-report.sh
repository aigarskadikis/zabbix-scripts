#!/bin/bash

#check current SELinux status
getenforce

#turn of SELinux
setenforce 0

#install git and vim
yum install git vim -y

#install version 0.9.4
curl -L "https://drive.google.com/uc?export=download&id=0B_VNwWso1iSQcGJqamQ1dFVSWWM" -o ~/zabbix-pdf-report-0.9.4.tgz

#look where is zabbix front end directory
find / -name trigger_prototypes.php

#download code
tar -xvzf ~/zabbix-pdf-report-0.9.4.tgz -C /usr/share/zabbix

#move to the frontend dir
cd /usr/share/zabbix/report

#enter credentials
vim config.inc.php
#$z_server       = 'http://192.168.3.246/zabbix/';
#$z_user         = 'Admin';
#$z_pass         = 'zabbix';

#go to
http://192.168.3.246/zabbix/report
