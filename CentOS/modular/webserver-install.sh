#!/bin/bash

#enable rhel-7-server-optional-rpms repository. This is neccessary to successfully install frontend
yum install yum-utils -y
yum-config-manager --enable rhel-7-server-optional-rpms

#install zabbix frontend
yum install httpd -y
yum install zabbix-web-mysql-$1 -y
