#!/bin/bash

#install wget utility
yum install wget -y

#installd development 
yum groupinstall 'Development tools'

#additional libraries
yum install krb5-devel libidn-devel libssh2-devel nss-devel openldap-devel stunnel zlib-devel perl-Time-HiRes valgrind

@
useradd builduser


#download curl source
wget http://vault.centos.org/7.4.1708/updates/Source/SPackages/curl-7.29.0-42.el7_4.1.src.rpm


yum install mock -y
groupadd mockbuild
useradd -g mockbuild -s /sbin/nologin mockbuild

#rebuil curl
rpmbuild --rebuild curl-7.29.0-42.el7_4.1.src.rpm

#go to dir wher new curl is having a good time
pushd ~builduser/rpmbuild/RPMS/x86_64/

#install new curl version
yum install curl-7.29.0-42.el6.1.x86_64.rpm libcurl-7.29.0-42.el6.1.x86_64.rpm libcurl-devel-7.29.0-42.el6.1.x86_64.rpm

#install zabbix repo
yum install http://repo.zabbix.com/zabbix/3.4/rhel/6/x86_64/zabbix-release-3.4-1.el6.noarch.rpm

#install developement packages just to satisfy zabbix compilation
yum install mysql-devel postgresql-devel net-snmp-devel gnutls-devel sqlite-devel unixODBC-devel OpenIPMI-devel java-devel libxml2-devel iksemel-devel






rpmbuild --rebuild



