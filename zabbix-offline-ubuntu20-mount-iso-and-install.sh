#!/bin/bash

# use WinSCP to upload '/tmp/zabbix-offline-install-ubuntu20.iso'

# create a directory where to mount ISO
mkdir /mnt/apt

# mount ISO
mount /tmp/zabbix-offline-install-ubuntu20.iso /mnt/apt

# create a backup of original repos
cp /etc/apt/sources.list /etc/apt/sources.list.original

# enable only offline
echo "deb [trusted=yes] file:/mnt/apt ./" | sudo tee /etc/apt/sources.list

# refresh apt
apt update
# now apt relies only what is in the ISO

# install MySQL server
apt install mysql-server

# follow official instruction to setup Zabbix with MySQL and NGINX on Ubuntu 20
# https://www.zabbix.com/download?zabbix=5.0&os_distribution=ubuntu&os_version=20.04_focal&db=mysql&ws=nginx

# bring back default repo 
cat /etc/apt/sources.list.original > /etc/apt/sources.list

# umount ISO
umount /mnt/apt
