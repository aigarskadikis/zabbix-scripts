#!/bin/bash

#======================================================================================
# Package                  Arch       Version           Repository                Size
#======================================================================================
#Installing:
# zabbix-proxy-sqlite3     x86_64     5.0.6-1.el8       zabbix                   1.0 M
#Installing dependencies:
# OpenIPMI-libs            x86_64     2.0.27-1.el8      baseos                   507 k
# fping                    x86_64     3.16-1.el8        zabbix-non-supported      51 k
# libtool-ltdl             x86_64     2.4.6-25.el8      baseos                    58 k
# net-snmp-libs            x86_64     1:5.8-17.el8      baseos                   823 k
# unixODBC                 x86_64     2.3.7-1.el8       appstream                458 k

# zabbix-agent           x86_64           5.0.6-1.el8           zabbix           464 k

# Installing:
# vim-enhanced          x86_64        2:8.0.1763-15.el8         appstream        1.4 M
#Installing dependencies:
# gpm-libs              x86_64        1.20.7-15.el8             appstream         39 k
# vim-common            x86_64        2:8.0.1763-15.el8         appstream        6.3 M
# vim-filesystem        noarch        2:8.0.1763-15.el8         appstream         48 k





echo 1 | sudo tee /proc/sys/vm/overcommit_memory
sudo dd if=/dev/zero of=/myswap1 bs=1M count=1024 && sudo chown root:root /myswap1 && sudo chmod 0600 /myswap1 && sudo mkswap /myswap1 && sudo swapon /myswap1 && free -m
sudo dd if=/dev/zero of=/myswap2 bs=1M count=1024 && sudo chown root:root /myswap2 && sudo chmod 0600 /myswap2 && sudo mkswap /myswap2 && sudo swapon /myswap2 && free -m

# install zabbix repo
rpm -Uvh https://repo.zabbix.com/zabbix/5.0/rhel/8/x86_64/zabbix-release-5.0-1.el8.noarch.rpm

# clean package manager cache
dnf clean all

# install proxy with sqlite3 db at backend
dnf -y install zabbix-proxy-sqlite3
# install agent
dnf -y install zabbix-agent
dnf -y install vim

# check home for zabbix
grep zabbix /etc/passwd
mkdir -p /var/lib/zabbix && chown -R zabbix. /var/lib/zabbix


vim /etc/zabbix/zabbix_proxy.conf
# delete 'Hostname=Zabbix proxy' 
# install 'HostnameItem=system.run[hostname --short]'
# install database location to 'DBName=/var/lib/zabbix/zabbix_proxy'


vim /etc/zabbix/zabbix_proxy.conf
# delete 'Hostname=Zabbix server'
# install 'HostnameItem=system.run[hostname --short]'
# install 'HostMetadataItem=system.sw.os'


systemctl status zabbix-proxy
systemctl status zabbix-agent

systemctl start zabbix-proxy zabbix-agent

systemctl enable zabbix-proxy zabbix-agent


