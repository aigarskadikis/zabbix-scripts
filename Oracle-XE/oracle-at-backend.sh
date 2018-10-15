# this instruction shows how to setup oracle XE on CentOS 7.5 and install zabbix server with oracle database at the backend.

yum -y install gcc gcc-c++ make gnutls-devel libxml2-devel unixODBC-devel net-snmp-devel libssh2-devel OpenIPMI-devel libevent-devel libcurl-devel openldap-devel bc net-tools vim unzip
rpm -i https://repo.zabbix.com/non-supported/rhel/7/x86_64/iksemel-1.4-2.el7.centos.x86_64.rpm
rpm -i https://repo.zabbix.com/non-supported/rhel/7/x86_64/iksemel-devel-1.4-2.el7.centos.x86_64.rpm

# this file must be placed on /root
# http://download.oracle.com/otn/linux/oracle11g/xe/oracle-xe-11.2.0-1.0.x86_64.rpm.zip
# http://download.oracle.com/otn/linux/instantclient/11204/oracle-instantclient11.2-basic-11.2.0.4.0-1.x86_64.rpm
# http://download.oracle.com/otn/linux/instantclient/11204/oracle-instantclient11.2-devel-11.2.0.4.0-1.x86_64.rpm
# http://download.oracle.com/otn/linux/instantclient/11204/oracle-instantclient11.2-jdbc-11.2.0.4.0-1.x86_64.rpm
# http://download.oracle.com/otn/linux/instantclient/11204/oracle-instantclient11.2-odbc-11.2.0.4.0-1.x86_64.rpm
# http://download.oracle.com/otn/linux/instantclient/11204/oracle-instantclient11.2-tools-11.2.0.4.0-1.x86_64.rpm

# install vagrant SSH key for future passwordless root access
sudo su
echo "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA6NF8iallvQVp22WDkTkyrtvp9eWW6A8YVr+kz4TjGYe7gHzIw+niNltGEFHzD8+v1I2YJ6oXevct1YeS0o9HZyN1Q9qgCgzUFtdOKLv6IedplqoPkcmF0aYet2PkEDo3MlTBckFXPITAMzF8dJSIFo9D8HfdOV0IAdx4O7PtixWKn5y2hMNG0zQPyUecp4pzC6kivAIhyfHilFR61RGL+GPXQ2MWZWFYbAGjyiYJnAmCP3NOTd0jMZEnDkbUvxhMmBYSdETk1rRgm+R4LOzFUGaHqHDLKLX+FIPKcF96hrucXzcWyLbIbEgE98OHlnVYCzRdK8jlqm8tehUc9c9WhQ== imported-openssh-key" > ~/.ssh/authorized_keys
chmod -R 600 ~/.ssh/authorized_keys

sysctl kernel.shmmax # check shmmax. must be 4294967295
echo "kernel.shmmax = 4294967295" >> /etc/sysctl.conf # install shmmax=4294967295 globaly at the next boot
sysctl -w kernel.shmmax=4294967295 # set shmmax=4294967295 now!
sysctl kernel.shmmax # check again live shmmax value

sysctl kernel.shmall # shmall must be 2097152
echo "kernel.shmall = 2097152" >> /etc/sysctl.conf # install shmall=2097152 at the next boot
sysctl -w kernel.shmall=2097152 # set shmall=2097152 now!
sysctl kernel.shmall # check again live shmall value

unzip oracle-xe-11.2.0-1.0.x86_64.rpm.zip
cd ~/Disk1

rpm -i oracle-xe-11.2.0-1.0.x86_64.rpm

time /etc/init.d/oracle-xe configure

# Lets set database password '5sRj4GXspvDKsBXW' for SYS and SYSTEM account

su - oracle
echo $ORACLE_HOME
echo ". /u01/app/oracle/product/11.2.0/xe/bin/oracle_env.sh"> ~/.bash_profile
exit
su - oracle
echo $ORACLE_HOME

# download archive into oracle profile
cd
v=4.0.0
curl -L "http://downloads.sourceforge.net/project/zabbix/ZABBIX%20Latest%20Stable/$v/zabbix-$v.tar.gz" -o zabbix-$v.tar.gz
tar -vzxf zabbix-$v.tar.gz -C .
cd ~/zabbix-$v/database/oracle
cp *.sql ~
sed -i 's%/home/zabbix/zabbix/create/output_png%/u01/app/oracle/zabbix-4.0.0/misc/images%g' ~/images.sql


### run as oracle user
sqlplus sys as sysdba
# '5sRj4GXspvDKsBXW'

# This should show:
# Connected to:
# Oracle Database 11g Express Edition Release 11.2.0.2.0 - 64bit Production
#

# startup
# ORA-01078: failure in processing system parameters
# LRM-00109: could not open parameter file '/u01/app/oracle/product/11.2.0/xe/dbs/initzabbix.ora'

select parameter,value from v$nls_parameters where parameter='NLS_CHARACTERSET' or parameter='NLS_NCHAR_CHARACTERSET';
# this should report
# NLS_CHARACTERSET
# AL32UTF8

# NLS_NCHAR_CHARACTERSET
# UTF8

# if not then execute this commands

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


select * from v$sysstat;
# ORA-01034: ORACLE not available
# Process ID: 0
# Session ID: 0 Serial number: 0
# to solve this error please add '. /u01/app/oracle/product/11.2.0/xe/bin/oracle_env.sh' inside '~/.bash_profile' under user 'oracle'

# https://uberdev.wordpress.com/2011/12/07/zabbix-deployment-on-rhel-with-oracle/
CREATE TABLESPACE "ZABBIX_TS" DATAFILE '/u01/app/oracle/oradata/XE/zabbix_ts.dbf' SIZE 100M AUTOEXTEND ON NEXT 536870912 MAXSIZE 4G LOGGING ONLINE PERMANENT BLOCKSIZE 8192 EXTENT MANAGEMENT LOCAL AUTOALLOCATE SEGMENT SPACE MANAGEMENT AUTO;
CREATE USER zabbix IDENTIFIED BY zabbix DEFAULT TABLESPACE ZABBIX_TS;
GRANT DBA TO zabbix WITH ADMIN OPTION;
exit

# connect to database zabbix
sqlplus zabbix/zabbix

select parameter,value from v$nls_parameters where parameter='NLS_CHARACTERSET' or parameter='NLS_NCHAR_CHARACTERSET';

SET DEFINE OFF 


@/u01/app/oracle/schema.sql
# stop here if you setting up proxy

### for images copy image files to coresponding dir with oracle user read permissions
@/u01/app/oracle/images.sql

# BEGIN
# *
# ERROR at line 1:
# ORA-22288: file or LOB operation FILEOPEN failed
# No such file or directory
# ORA-06512: at "SYS.DBMS_LOB", line 805
# ORA-06512: at "ZABBIX.LOAD_IMAGE", line 8
# ORA-06512: at line 2

@/u01/app/oracle/data.sql

exit

exit # exit oracle user


cd
v=4.0.0
curl -L "http://downloads.sourceforge.net/project/zabbix/ZABBIX%20Latest%20Stable/$v/zabbix-$v.tar.gz" -o zabbix-$v.tar.gz
tar -vzxf zabbix-$v.tar.gz -C .
cd zabbix-$v


export ORACLE_HOME=/u01/app/oracle/product/11.2.0/xe
export LD_LIBRARY_PATH=$ORACLE_HOME/lib
groupadd zabbix
useradd -g zabbix zabbix

# configure proxy
./configure --enable-proxy --enable-agent --with-oracle --with-libcurl --with-libxml2 --with-ssh2 --with-net-snmp --with-openipmi --with-jabber --with-openssl --with-unixodbc --sysconfdir=/etc/zabbix --prefix=/usr

time make # compile

make install # install

cat /u01/app/oracle/product/11.2.0/xe/network/admin/tnsnames.ora
vim /etc/zabbix/zabbix_proxy.conf
# Hostname=oracle-xe
# LogFile=/tmp/zabbix_proxy.log
# DBName=XE
# DBUser=zabbix
# DBPassword=zabbix
# DBPort=1521
# Timeout=4
# LogSlowQueries=3000

# test if proxy is working
su - zabbix
# zabbix_proxy: error while loading shared libraries: libclntsh.so.11.1: cannot open shared object file: No such file or directory
echo ". /u01/app/oracle/product/11.2.0/xe/bin/oracle_env.sh">> ~/.bash_profile
echo "export LD_LIBRARY_PATH=\$ORACLE_HOME/lib">> ~/.bash_profile

zabbix_proxy -f

cd 

# install other 
rpm -i oracle-instantclient11.2-basic-11.2.0.4.0-1.x86_64.rpm # this is needed for httpd client to be able to connect
rpm -i oracle-instantclient11.2-devel-11.2.0.4.0-1.x86_64.rpm
rpm -i oracle-instantclient11.2-jdbc-11.2.0.4.0-1.x86_64.rpm
rpm -i oracle-instantclient11.2-odbc-11.2.0.4.0-1.x86_64.rpm # odbc connector. needed to use direct SQL statements
rpm -i oracle-instantclient11.2-tools-11.2.0.4.0-1.x86_64.rpm

# zabbix_server: error while loading shared libraries: libclntsh.so.11.1: cannot open shared object file: No such file or directory


# bash: pecl: command not found
yum -y install php-pear

# WARNING: channel "pecl.php.net" has updated its protocols, use "pecl channel-update pecl.php.net" to update
# pecl/oci8 requires PHP (version >= 7.0.0), installed version is 5.4.16

yum install epel-release
yum install http://rpms.remirepo.net/enterprise/remi-release-7.rpm
yum-config-manager --enable remi-php70
yum install php php-mcrypt php-cli php-gd php-curl php-mysql php-ldap php-zip php-fileinfo
php -v

# PHP Parse error:  syntax error, unexpected 'new' (T_NEW) in /usr/share/pear/PEAR/Frontend.php on line 91
yum update -y

pecl install oci8
pecl channel-update pecl.php.net
# Can't find PHP headers in /usr/include/php
yum -y install php-devel

# /var/tmp/oci8/php_oci8_int.h:46:29: fatal error: oci8_dtrace_gen.h: No such file or directory
export PHP_DTRACE=yes
pecl install oci8
# '/u01/app/oracle/product/11.2.0/xe'

# Build process completed successfully
# Installing '/usr/lib64/php/modules/oci8.so'
# install ok: channel://pecl.php.net/oci8-2.1.8
# configuration option "php_ini" is not set to php.ini location
# You should add "extension=oci8.so" to php.ini



# 
# https://ucblog.ru/2018/04/zabbix-%D0%BC%D0%BE%D0%BD%D0%B8%D1%82%D0%BE%D1%80%D0%B8%D0%BD%D0%B3-%D0%B1%D0%B0%D0%B7%D1%8B-%D0%B4%D0%B0%D0%BD%D0%BD%D1%8B%D1%85-oracle/
# https://www.tekstream.com/oracle-error-messages/ora-01034-oracle-not-available/

# https://www.zabbix.com/documentation/4.0/manual/appendix/install/db_scripts

# https://docs.oracle.com/cd/E17781_01/install.112/e18803/toc.htm#XEINW144