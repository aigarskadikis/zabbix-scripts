#!/bin/bash

yum -y install yum-utils

# add docer repo
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

# see what is inside
cat /etc/yum.repos.d/docker-ce.repo

# install docker community edition
yum -y install docker-ce

# start docker
systemctl start docker

# enable at startup
systemctl enable docker


###### prepare docker-compose ########

# install pip
yum -y install epel-release && yum -y install python-pip
 
# install docker-compose
pip install -U docker-compose
  
# (optional) upgrade pip
pip install --upgrade pip

# install git
yum -y install git

# install docker zabbix repo
cd
git clone https://github.com/zabbix/zabbix-docker.git
git checkout 4.0
git checkout 4.2

# the magic happens here. remove the component you do not like
vim docker-compose_v3_alpine_mysql_latest.yaml

# or use yq utility to remove some parts

docker-compose -f docker-compose_v3_alpine_mysql_latest.yaml up -d

# observe the processes on fire
docker ps

# search the id for mysql container
docker ps | grep " mysql:" | grep -E -o "^[0-9a-f]+"

# open bash for particular container
docker exec -it 2fbaaa453db3 /bin/bash


# delete all conteiners. fresh start
docker rm -f $(docker ps -aq)

# install ipmi simpulator using instructions from
# https://github.com/vapor-ware/ipmi-simulator
docker pull vaporio/ipmi-simulator

# run simulator
docker run -d -p 623:623/udp vaporio/ipmi-simulator

# install ipmitool
yum install ipmitool

# test
ipmitool -H 127.0.0.1 -U ADMIN -P ADMIN -I lanplus chassis status



# turn on zabbix proxy in active mode
docker run --name zbx-docker-prx --network=bridge --restart unless-stopped \
-itd --env ZBX_PROXYMODE=0 --env ZBX_SERVER_HOST=ec2-35-166-97-138.us-west-2.compute.amazonaws.com -p \
10061:10051 --env ZBX_CONFIGFREQUENCY=300 --env ZBX_HOSTNAME=zbx-docker-prx zabbix/zabbix-proxy-sqlite3:latest

# list all containers
docker ps -a

# remove containers
docker remove --name zbx-docker-prx

docker run --name zbx-docker-prx --network=bridge --restart unless-stopped \
-itd --env ZBX_PROXYMODE=0 --env ZBX_SERVER_HOST=ec2-35-166-97-138.us-west-2.compute.amazonaws.com -p \
10061:10051 --env ZBX_CONFIGFREQUENCY=300 --env ZBX_HOSTNAME=zbx-docker-prx zabbix/zabbix-proxy-sqlite3:latest


docker stop zbx-docker-prx

docker stop wizardly_elgamal

docker start zbx-docker-prx



