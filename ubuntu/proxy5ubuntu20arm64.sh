#!/bin/bash

maj=5.0
min=2

cd /dev/shm

curl -L "https://cdn.zabbix.com/zabbix/sources/stable/$maj/zabbix-$maj.$min.tar.gz" -o zabbix-$maj.$min.tar.gz

tar -vzxf zabbix-$maj.$min.tar.gz

cd zabbix-$maj.$min

./configure --enable-agent

make install > /dev/shm/out.log

#  --bindir=DIR            user executables [EPREFIX/bin]
#  --sbindir=DIR           system admin executables [EPREFIX/sbin]
#  --libexecdir=DIR        program executables [EPREFIX/libexec]
#  --sysconfdir=DIR        read-only single-machine data [PREFIX/etc]

./configure --sysconfdir=/etc/zabbix --prefix=/usr --enable-proxy --enable-agent --with-sqlite3 --with-libcurl --with-libxml2 --with-ssh2 --with-net-snmp --with-openssl --with-unixodbc 

./configure --sysconfdir=/etc/zabbix --prefix=/usr --enable-proxy --enable-agent --enable-agent2 --with-sqlite3 --with-libcurl --with-libxml2 --with-ssh2 --with-net-snmp --with-openssl --with-unixodbc --enable-java

# configure: error: no acceptable C compiler found in $PATH
sudo apt -y install build-essential

# configure: error: SQLite3 library not found
sudo apt -y install libsqlite3-dev

# configure: error: LIBXML2 library not found
sudo apt -y install libxml2-dev pkg-config

# configure: error: unixODBC library not found
sudo apt -y install unixodbc-dev

# configure: error: Invalid Net-SNMP directory - unable to find net-snmp-config
sudo apt -y install libsnmp-dev

# configure: error: SSH2 library not found
sudo apt -y install libssh2-1-dev

# configure: error: Unable to use libevent (libevent check failed)
sudo apt -y install libevent-dev

# configure: error: Curl library not found
sudo apt -y install libcurl4-openssl-dev

# configure: error: Unable to use libpcre (libpcre check failed)
sudo apt -y install libpcre3-dev

# configure: error: Unable to find "go" executable in path
sudo apt -y install golang

# configure: error: Unable to find "javac" executable in path
sudo apt -y install openjdk-8-jdk



