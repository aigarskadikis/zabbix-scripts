#!/bin/bash

#open 80 and 443 into firewall
systemctl enable firewalld
systemctl start firewalld

firewall-cmd --permanent --add-service=http
firewall-cmd --permanent --add-service=https
firewall-cmd --add-port=162/udp --permanent
firewall-cmd --add-port=3000/tcp --permanent #for grafana reporting server https://www.digitalocean.com/community/tutorials/how-to-install-and-configure-grafana-to-plot-beautiful-graphs-from-zabbix-on-centos-7
firewall-cmd --reload
