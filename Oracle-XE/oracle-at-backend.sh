# the goal of this instruction is to test oracle database monitoring through linuxODBC driver. So we will set up proxy with 'Oracle 11.2g express edition' so have something to monitor.

# 2 GB of RAM must be persistent

# install vagrant SSH key for future passwordless root access
echo "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA6NF8iallvQVp22WDkTkyrtvp9eWW6A8YVr+kz4TjGYe7gHzIw+niNltGEFHzD8+v1I2YJ6oXevct1YeS0o9HZyN1Q9qgCgzUFtdOKLv6IedplqoPkcmF0aYet2PkEDo3MlTBckFXPITAMzF8dJSIFo9D8HfdOV0IAdx4O7PtixWKn5y2hMNG0zQPyUecp4pzC6kivAIhyfHilFR61RGL+GPXQ2MWZWFYbAGjyiYJnAmCP3NOTd0jMZEnDkbUvxhMmBYSdETk1rRgm+R4LOzFUGaHqHDLKLX+FIPKcF96hrucXzcWyLbIbEgE98OHlnVYCzRdK8jlqm8tehUc9c9WhQ== imported-openssh-key" > ~/.ssh/authorized_keys
chmod -R 600 ~/.ssh/authorized_keys

# set hostname to 'oracle-be.lan' which stands for oracle back-end
nmtui
reboot
# reboot computer so when you execute '/etc/init.d/oracle-xe configure' the oracle wizard will really take up the right hostname. Without reboot it will not work.

# go to https://www.oracle.com/technetwork/database/database-technologies/express-edition/downloads/index.html
# download:
# * oracle-xe-11.2.0-1.0.x86_64.rpm.zip
# and place this file on /root 

# go to https://www.oracle.com/technetwork/topics/linuxx86-64soft-092277.html
# download:
# * oracle-instantclient11.2-basic-11.2.0.4.0-1.x86_64.rpm
# * oracle-instantclient11.2-odbc-11.2.0.4.0-1.x86_64.rpm
# and place these files on /root 

# install prerequsites for everything
yum -y install gcc make net-snmp-devel libssh2-devel libcurl-devel unixODBC-devel bc net-tools vim unzip mlocate policycoreutils-python
# bc, net-tools are required for oracle setup

# according to https://docs.oracle.com/cd/E11882_01/install.112/e24326/toc.htm#BHCIFHBE some modifications must be adjusted to kernel parameters
sysctl kernel.shmmax # check shmmax. must be 4294967295
echo "kernel.shmmax = 4294967295" >> /etc/sysctl.conf # install shmmax=4294967295 globaly at the next boot
sysctl -w kernel.shmmax=4294967295 # set shmmax=4294967295 now!
sysctl kernel.shmmax # check again live shmmax value

sysctl kernel.shmall # shmall must be 2097152
echo "kernel.shmall = 2097152" >> /etc/sysctl.conf # install shmall=2097152 at the next boot
sysctl -w kernel.shmall=2097152 # set shmall=2097152 now!
sysctl kernel.shmall # check again live shmall value

unzip oracle-xe-11.2.0-1.0.x86_64.rpm.zip && cd ~/Disk1 && rpm -i oracle-xe-11.2.0-1.0.x86_64.rpm && time /etc/init.d/oracle-xe configure
# Let's set database password '5sRj4GXspvDKsBXW' for SYS and SYSTEM account

# https://help.ubuntu.com/community/Oracle%20Instant%20Client
# install oracle path globaly
echo "/u01/app/oracle/product/11.2.0/xe/lib" > /etc/ld.so.conf.d/oracle.conf
chmod o+r /etc/ld.so.conf.d/oracle.conf
ldconfig -v

cat <<'EOF'> /etc/profile.d/oracle.sh
. /u01/app/oracle/product/11.2.0/xe/bin/oracle_env.sh
export LD_LIBRARY_PATH=$ORACLE_HOME/lib
EOF
chmod o+r /etc/profile.d/oracle.sh

su - oracle
echo $ORACLE_HOME
echo $LD_LIBRARY_PATH
tnsping XE # try to ping TNSNAME. to this point it should retreive 'OK' at the last line

# download zabbix source archive into oracle profile
cd
v=4.0.0
curl -L "http://downloads.sourceforge.net/project/zabbix/ZABBIX%20Latest%20Stable/$v/zabbix-$v.tar.gz" -o zabbix-$v.tar.gz
tar -vzxf zabbix-$v.tar.gz -C .
cd ~/zabbix-$v/database/oracle
cp *.sql ~

# enter database administration with oracle super user 
sqlplus sys as sysdba
# '5sRj4GXspvDKsBXW'

# This should show:
# Connected to:
# Oracle Database 11g Express Edition Release 11.2.0.2.0 - 64bit Production

select parameter,value from v$nls_parameters where parameter='NLS_CHARACTERSET' or parameter='NLS_NCHAR_CHARACTERSET';
# this should report
# NLS_CHARACTERSET
# AL32UTF8

# NLS_NCHAR_CHARACTERSET
# UTF8

# if not then execute these commands:

shutdown immediate
startup mount
alter system enable restricted session;
alter system set job_queue_processes=0;
alter system set aq_tm_processes=0;
alter database open;
ALTER DATABASE NATIONAL CHARACTER SET internal_use UTF8;
shutdown immediate
startup

# check again
select parameter,value from v$nls_parameters where parameter='NLS_CHARACTERSET' or parameter='NLS_NCHAR_CHARACTERSET';

# test some status
select * from v$sysstat;

# https://uberdev.wordpress.com/2011/12/07/zabbix-deployment-on-rhel-with-oracle/
# create zabbix database (table space)
CREATE TABLESPACE "ZABBIX_TS" DATAFILE '/u01/app/oracle/oradata/XE/zabbix_ts.dbf' SIZE 100M AUTOEXTEND ON NEXT 536870912 MAXSIZE 4G LOGGING ONLINE PERMANENT BLOCKSIZE 8192 EXTENT MANAGEMENT LOCAL AUTOALLOCATE SEGMENT SPACE MANAGEMENT AUTO;
CREATE USER zabbix IDENTIFIED BY zabbix DEFAULT TABLESPACE ZABBIX_TS;
GRANT DBA TO zabbix WITH ADMIN OPTION;
exit

# connect to database zabbix. this is a way how to authorize into database with one-liner
sqlplus zabbix/zabbix

# last check if the encoding is right
select parameter,value from v$nls_parameters where parameter='NLS_CHARACTERSET' or parameter='NLS_NCHAR_CHARACTERSET';
# this should report:
# NLS_CHARACTERSET
# AL32UTF8
# 
# NLS_NCHAR_CHARACTERSET
# UTF8

SET DEFINE OFF 

@/u01/app/oracle/schema.sql

# exit the database client
exit

# exit oracle user
exit 

# download source of zabbix
cd
v=4.0.0
curl -L "http://downloads.sourceforge.net/project/zabbix/ZABBIX%20Latest%20Stable/$v/zabbix-$v.tar.gz" -o zabbix-$v.tar.gz
tar -vzxf zabbix-$v.tar.gz -C .
cd zabbix-$v

# create user 'zabbix' and assign it to group 'zabbix'
groupadd zabbix
useradd -g zabbix zabbix

# configure proxy with agent
#./configure --enable-proxy --enable-agent --with-oracle --with-unixodbc --with-net-snmp --with-ssh2 --with-openssl --with-libcurl --sysconfdir=/etc/zabbix --prefix=/usr

# maybe it is ok te manage the agent binary from repository.
# only the proxy (without agent) will be maintained 
./configure --enable-proxy --with-oracle --with-unixodbc --with-net-snmp --with-ssh2 --with-openssl --with-libcurl --sysconfdir=/etc/zabbix --prefix=/usr

# compile
time make 

# install everything
make install

grep -v "^$\|#" /etc/zabbix/zabbix_proxy.conf
# modify the values to look similar to this
Server=ec2-35-166-97-138.us-west-2.compute.amazonaws.com
Hostname=orcl-xe-pxy
LogFile=/tmp/zabbix_proxy.log
DBName=XE
DBUser=zabbix
DBPassword=zabbix
DBPort=1521
Timeout=4
LogSlowQueries=3000

# OR you can overwrite the conf:
cp /etc/zabbix/{zabbix_proxy.conf,original.zabbix_proxy.conf}
# fast configuration install. overwrite original
cat >/etc/zabbix/zabbix_proxy.conf<< EOL
Server=ec2-35-166-97-138.us-west-2.compute.amazonaws.com
Hostname=orcl-xe-pxy
LogFile=/tmp/zabbix_proxy.log
DBName=XE
DBUser=zabbix
DBPassword=zabbix
DBPort=1521
Timeout=4
LogSlowQueries=3000
EOL

# check current TNS strings installed
cat /u01/app/oracle/product/11.2.0/xe/network/admin/tnsnames.ora

# backup config
cp /u01/app/oracle/product/11.2.0/xe/network/admin/{tnsnames.ora,original.tnsnames.ora}

# let's replace whatever DNS name is used with 127.0.0.1
sed -i "s|$(hostname)|127.0.0.1|g" /u01/app/oracle/product/11.2.0/xe/network/admin/tnsnames.ora
# for example if the hostname is like '4d61050b753b.sn.mynetname.net' then it won't work witch such long name. Don't know why.

# see if changes has been installed
cat /u01/app/oracle/product/11.2.0/xe/network/admin/tnsnames.ora

# test if proxy is working
su - zabbix -s /bin/bash
# zabbix_proxy: error while loading shared libraries: libclntsh.so.11.1: cannot open shared object file: No such file or directory

# allow to communicate with oracle engine right now!
export ORACLE_HOME=/u01/app/oracle/product/11.2.0/xe
export LD_LIBRARY_PATH=$ORACLE_HOME/lib

# launch the proxy server now in foreground
zabbix_proxy -f

# Ctrl+C and exit zabbix user
exit

# open another session and check the logs or hit Ctrl+C in this session
cat /tmp/zabbix_proxy.log


# set up ODBC connection
cd 

rpm -i oracle-instantclient11.2-basic-11.2.0.4.0-1.x86_64.rpm # required for odbc 
rpm -i oracle-instantclient11.2-odbc-11.2.0.4.0-1.x86_64.rpm # odbc connector. needed to use direct SQL statements

# fix some error mentioned http://docs.adaptivecomputing.com/9-1-0/MWS/Content/topics/moabWorkloadManager/topics/databases/oracle.html
updatedb && locate libodbcinst
cd /usr/lib64
ln -s libodbcinst.so.2 libodbcinst.so.1
chmod 755 /usr/lib/oracle/11.2/client64/lib/lib*
ldd /usr/lib/oracle/11.2/client64/lib/libsqora.so.11.1

# check is [isql] utility is installed
isql

# backup original file which contains samples for MySQL and PostgreSQL
cp /etc/{odbcinst.ini,original.odbcinst.ini}

# install/overwrite new connection driver definition regarding to oracle 11.2 xe
cat >/etc/odbcinst.ini<< EOL
[Oracle 11g ODBC driver]
Description     = Oracle ODBC driver for Oracle 11g
Driver          = /usr/lib/oracle/11.2/client64/lib/libsqora.so.11.1
Setup           =
FileUsage       =
CPTimeout       =
CPReuse         =
Driver Logging  = 7
 
[ODBC]
Trace = Yes
TraceFile = /tmp/odbc.log
ForceTrace = Yes
Pooling = No
DEBUG = 1
EOL

# install connection details. note the the line with "DNS = XE". This is another place where hostname oracle-be.lan matters!
cat >/etc/odbc.ini<< EOL
[ODBC]
Application Attributes = T
Attributes = W
BatchAutocommitMode = IfAllSuccessful
BindAsFLOAT = F
CloseCursor = F
DisableDPM = F
DisableMTS = T
Driver = Oracle 11g ODBC driver
DSN = XE
EXECSchemaOpt =
EXECSyntax = T
Failover = T
FailoverDelay = 10
FailoverRetryCount = 10
FetchBufferSize = 64000
ForceWCHAR = F
Lobs = T
Longs = T
MaxLargeData = 0
MetadataIdDefault = F
QueryTimeout = T
ResultSets = T
ServerName = 127.0.0.1
SQLGetData extensions = F
Translation DLL =
Translation Option = 0
DisableRULEHint = T
UserID = zabbix
Password = zabbix
StatementCache=F
CacheBufferSize=20
UseOCIDescribeAny=F
MaxTokenSize=8192
EOL

# move to zabbix user because it know (~/.bach_profile) how to communicate to oracle
su - zabbix

# test connection
isql -v ODBC
# this should report
# +---------------------------------------+
# | Connected!                            |
# |                                       |
# | sql-statement                         |
# | help [tablename]                      |
# | quit                                  |
# |                                       |
# +---------------------------------------+

#test some queries
select count(*) "procnum" from gv$process
select to_char((sysdate-startup_time)*86400, 'FM99999999999999990') retvalue from gv$instance

# exit isql utility
quit

# attach the template inside zabbix

# exit zabbix user
exit

# install init file. the difference between this and original is 'PIDFile=/tmp/zabbix_proxy.pid'
# be careful when modify this script. dolar signs must be escaped.
cat >/usr/lib/systemd/system/zabbix-proxy.service<< EOL
[Unit]
Description=Zabbix Proxy
After=syslog.target
After=network.target

[Service]
Environment="CONFFILE=/etc/zabbix/zabbix_proxy.conf"
EnvironmentFile=-/etc/sysconfig/zabbix-proxy
Type=forking
Restart=on-failure
PIDFile=/tmp/zabbix_proxy.pid
KillMode=control-group
ExecStart=/usr/sbin/zabbix_proxy -c \$CONFFILE
ExecStop=/bin/kill -SIGTERM \$MAINPID
RestartSec=10s
TimeoutSec=0

[Install]
WantedBy=multi-user.target
EOL

# install environment file
cat >/etc/sysconfig/zabbix-proxy<< EOL
ORACLE_HOME=/u01/app/oracle/product/11.2.0/xe
LD_LIBRARY_PATH=/usr/lib64:/u01/app/oracle/product/11.2.0/xe/lib
ORACLE_SID=XE
PATH=/bin:/usr/bin:/usr/sbin:/u01/app/oracle/product/11.2.0/xe/bin

export ORACLE_HOME
export LD_LIBRARY_PATH
export ORACLE_SID
export PATH
EOL

systemctl daemon-reload
setenforce 0
systemctl stop zabbix-proxy

systemctl start zabbix-proxy
# show 'grep's which components are involved, not allowed
grep denied /var/log/audit/audit.log | sed "s/^.*denied /denied/g;s/ pid=[0-9]\+ \| ino=[0-9]\+//g;s/ name=.*scontext=\| path=.*scontext=/ /g" | sort | uniq | sed "s/^.*comm=.//g;s/. .*system_r:/.*/g;s/:.*//g" | sort|uniq | sed "s/^/grep \"comm.*/g;s/$/\" \/var\/log\/audit\/audit.log/g"

# install missing 
grep "comm.*zabbix_proxy.*zabbix_t" /var/log/audit/audit.log | audit2allow -M comm_zabbix_proxy_zabbix_t
semodule -i comm_zabbix_proxy_zabbix_t.pp

systemctl stop zabbix-proxy
setenforce 1
systemctl start zabbix-proxy
systemctl status zabbix-proxy
systemctl enable zabbix-proxy

# Problem:
# This system does not meet the minimum requirements for swap space.  Based on
# the amount of physical memory available on the system, Oracle Database 11g
# Express Edition requires 2048 MB of swap space. This system has 0 MB
# of swap space.  Configure more swap space on the system and retry the
# installation.
#
# Solution:
# dd if=/dev/zero of=/myswap bs=1M count=2048 && chmod 0600 /myswap && mkswap /myswap && swapon /myswap

# Problem:
# [01000][unixODBC][Driver Manager]Can't open lib '/usr/lib/oracle/11.2/client64/lib/libsqora.so.11.1' : file not found
# [ISQL]ERROR: Could not SQLConnect
# Solution:
# echo ". /u01/app/oracle/product/11.2.0/xe/bin/oracle_env.sh">> ~/.bash_profile
# echo "export LD_LIBRARY_PATH=\$ORACLE_HOME/lib">> ~/.bash_profile
 
# Problem:
# ORA-12154: TNS:could not resolve the connect identifier specified
# this may be related to long hostname. use 127.0.0.1 insted
