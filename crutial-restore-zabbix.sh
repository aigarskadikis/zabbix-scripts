#!/bin/bash

#push fresh lite image to micro sd card

#ssh must be enabled. this can be done by creating ssh file (without content) on boot partition

#all crucial files must be stored in boot partition in directory 'backup'

#after first boot please move to the root user and update system
#sudo su
apt-get update -y
apt-get dist-upgrade -y
apt-get update -y
apt-get install git -y
apt-get install tree -y
apt-get install vim -y

cd /home/pi/backup
cp -R * /
#set permissions

#install git keys
#allow only owner read and write to these keys
chmod 600 ~/.ssh/id_rsa #git private key
chmod 600 ~/.ssh/id_rsa.pub #git public key
chmod 644 ~/.gitconfig #email and username for git

chown -R zabbix:zabbix /home/zabbix
chown -R zabbix:zabbix /usr/local/share/zabbix
chmod 770 /usr/local/share/zabbix/externalscripts/*
chmod 600 /home/zabbix/.my.cnf

#install certboot agentls
curl -s https://dl.eff.org/certbot-auto > /usr/bin/certbot
chmod 770 /usr/bin/certbot
#integrate some certbot settings
mkdir -p /etc/letsencrypt
echo renew-hook = systemctl reload nginx> /etc/letsencrypt/cli.ini

mkdir ~/git
cd ~/git
git clone ssh://git@github.com/catonrug/zabbix-mariadb-nginx-raspbian-stretch.git

#remove symlink - default nginx sites
unlink /etc/nginx/sites-enabled/default
ln -s /etc/nginx/sites-available/5d61050b753b.sn.mynetname.net /etc/nginx/sites-enabled/5d61050b753b.sn.mynetname.net

#disable wifi module
#dtoverlay=pi3-disable-wifi

#backup database
#sudo mysqldump zabbix | bzip2 -9 > dbdump.bz2
#bzcat dbdump.bz2 | sudo mysql zabbix



