#!/bin/bash

#check current SELinux status
getenforce

#turn of SELinux
setenforce 0

#install vim
yum install vim -y

#download version 0.9.4
curl -L "https://drive.google.com/uc?export=download&id=0B_VNwWso1iSQcGJqamQ1dFVSWWM" -o ~/zabbix-pdf-report-0.9.4.tgz

#look where is zabbix front end directory
find / -name trigger_prototypes.php

#extract 'report' dir
tar -xvzf ~/zabbix-pdf-report-0.9.4.tgz -C /usr/share/zabbix

#move to the frontend dir
cd /usr/share/zabbix/report

#take a note what is direct ip address of server
ip a
#this will show ip address like 10.0.2.15

#enter credentials
vim config.inc.php
#$z_server       = 'http://10.0.2.15/zabbix/';
#$z_user         = 'Admin';
#$z_pass         = 'zabbix';

#based on port forwarding in VirtualBox
#Protocol: TCP, Host IP: 127.0.0.1, Host Port: 8030, Guest IP: 10.0.2.15, Guest Port:80
#https://1.bp.blogspot.com/-F-z-K3xfN2o/WuK9OSiTr5I/AAAAAAAAaFI/VHn-R5YByEscoW1H3aVri1sEsbbUg9w2gCLcBGAs/s1600/port-forwarding-virtualbox-zabbix.png
#you need to go to address
#http://localhost:8030/zabbix/report

#related
#https://catonrug.blogspot.com/2018/04/install-zabbix-dynamic-pdf-report.html
