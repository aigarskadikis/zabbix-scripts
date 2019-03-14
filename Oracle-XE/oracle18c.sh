#!/bin/bash

# RAM 1600MB minimum

# https://docs.oracle.com/en/database/oracle/oracle-database/18/xeinl/procedure-installing-oracle-database-xe.html

curl -o oracle-database-preinstall-18c-1.0-1.el7.x86_64.rpm https://yum.oracle.com/repo/OracleLinux/OL7/latest/x86_64/getPackage/oracle-database-preinstall-18c-1.0-1.el7.x86_64.rpm

yum -y localinstall oracle-database-preinstall-18c-1.0-1.el7.x86_64.rpm

# https://www.oracle.com/technetwork/database/database-technologies/express-edition/downloads/index.html
# the following package will install for 10 minutes or something
yum -y localinstall oracle-database-xe-18c-1.0-1.x86_64.rpm

# Running transaction
# [SEVERE] Oracle Database 18c Express Edition requires a minimum of 1GB of physical memory (RAM).  This system has 739 MB of RAM and does not meet minimum requirements.
# 
# error: %pre(oracle-database-xe-18c-1.0-1.x86_64) scriptlet failed, exit status 1
# Error in PREIN scriptlet in rpm package oracle-database-xe-18c-1.0-1.x86_64
#   Verifying  : oracle-database-xe-18c-1.0-1.x86_64                             1/1
# 
# Failed:
#   oracle-database-xe-18c.x86_64 0:1.0-1

# increase RAM in this case

# IN SUCCESS this will show
#   Installing : oracle-database-xe-18c-1.0-1.x86_64                             1/1
# [INFO] Executing post installation scripts...
# [INFO] Oracle home installed successfully and ready to be configured.
# To configure Oracle Database XE, optionally modify the parameters in '/etc/sysconfig/oracle-xe-18c.conf' and then execute '/etc/init.d/oracle-xe-18c configure' as root.
#   Verifying  : oracle-database-xe-18c-1.0-1.x86_64                             1/1
# 
# Installed:
#   oracle-database-xe-18c.x86_64 0:1.0-1

# to this point noone is listening on port 1521
netstat -tulpn | grep 1521

# see if free is 1.3GB
free -h

# lets configure oracle DB. This will take 22 minutes with 2 cores and 2500MB RAM. It will stuck on 47% for 15 minutes. that is normal
time /etc/init.d/oracle-xe-18c configure


# Specify a password to be used for database accounts. Oracle recommends that the password entered should be at least 8 characters in length, contain at least 1 uppercase character, 1 lower case character and 1 digit [0-9]. Note that the same password will be used for SYS, SYSTEM and PDBADMIN accounts:

# 5sRj4GXspvDKsBXW

# Confirm the password:
# Configuring Oracle Listener.
# Listener configuration succeeded.
# Configuring Oracle Database XE.
# [WARNING] [DBT-11205] Specified shared pool size does not meet the recommended minimum size requirement. This might cause database creation to fail.
#    ACTION: Specify at least (381 MB) for shared pool size.
# Enter SYS user password:
# *****************
# Enter SYSTEM user password:
# ******************
# Enter PDBADMIN User Password:
# *****************
# Prepare for db operation
# 7% complete
# Copying database files
# 8% complete
# [WARNING] ORA-00821: Specified value of sga_target 320M is too small, needs to be at least 396M
# ORA-01078: failure in processing system parameters
# 
# 9% complete
# [FATAL] ORA-01034: ORACLE not available
# 
# 29% complete
# 100% complete
# [FATAL] ORA-01034: ORACLE not available
# 
# 7% complete
# 0% complete
# Look at the log file "/opt/oracle/cfgtoollogs/dbca/XE/XE.log" for further details.
# 
# Database configuration failed. Check logs under '/opt/oracle/cfgtoollogs/dbca'.


cat /opt/oracle/cfgtoollogs/dbca/XE/XE.log
# [ 2019-03-14 19:47:29.105 EET ] [WARNING] [DBT-11205] Specified shared pool size does not meet the recommended minimum size requirement. This might cause database creation to fail.
# [ 2019-03-14 19:47:30.941 EET ] Prepare for db operation
# DBCA_PROGRESS : 7%
# [ 2019-03-14 19:47:31.607 EET ] Copying database files
# DBCA_PROGRESS : 8%
# [ 2019-03-14 19:47:34.335 EET ] [WARNING] ORA-00821: Specified value of sga_target 320M is too small, needs to be at least 396M
# ORA-01078: failure in processing system parameters
# 
# DBCA_PROGRESS : 9%
# [ 2019-03-14 19:47:34.339 EET ] [FATAL] ORA-01034: ORACLE not available
# 
# DBCA_PROGRESS : 29%
# DBCA_PROGRESS : 100%
# [ 2019-03-14 19:47:34.357 EET ] [FATAL] ORA-01034: ORACLE not available
# 
# DBCA_PROGRESS : 7%
# DBCA_PROGRESS : 0%

# increasing memory to 1600MB should solve the case

# Oracle Database instance XE is already configured.
# > /etc/oratab


#======= ON SUCCESS IT WILL SHOW OUTPUT

# [root@oracle18c ~]# time /etc/init.d/oracle-xe-18c configure
# Specify a password to be used for database accounts. Oracle recommends that the                                      password entered should be at least 8 characters in length, contain at least 1 u                                     ppercase character, 1 lower case character and 1 digit [0-9]. Note that the same                                      password will be used for SYS, SYSTEM and PDBADMIN accounts:
# Confirm the password:
# Configuring Oracle Listener.
# Listener configuration succeeded.
# Configuring Oracle Database XE.
# Enter SYS user password:
# *****************
# Enter SYSTEM user password:
# ***************
# Enter PDBADMIN User Password:
# ***************
# Prepare for db operation
# 7% complete
# Copying database files
# 29% complete
# Creating and starting Oracle instance
# 30% complete
# 31% complete
# 34% complete
# 38% complete
# 41% complete
# 43% complete
# Completing Database Creation
# 47% complete
# 50% complete
# Creating Pluggable Databases
# 54% complete
# 71% complete
# Executing Post Configuration Actions
# 93% complete
# Running Custom Scripts
# 100% complete
# Database creation complete. For details check the logfiles at:
#  /opt/oracle/cfgtoollogs/dbca/XE.
# Database Information:
# Global Database Name:XE
# System Identifier(SID):XE
# Look at the log file "/opt/oracle/cfgtoollogs/dbca/XE/XE.log" for further details.
# 
# Connect to Oracle Database using one of the connect strings:
#      Pluggable database: oracle18c/XEPDB1
#      Multitenant container database: oracle18c
# Use https://localhost:5500/em to access Oracle Enterprise Manager for Oracle Database XE
# 
# real    21m57.088s
# user    1m5.216s
# sys     0m6.781s



# cat /opt/oracle/cfgtoollogs/dbca/XE/XE.log
# [ 2019-03-14 20:41:52.413 EET ] Prepare for db operation
# DBCA_PROGRESS : 7%
# [ 2019-03-14 20:41:52.760 EET ] Copying database files
# DBCA_PROGRESS : 29%
# [ 2019-03-14 20:44:58.096 EET ] Creating and starting Oracle instance
# DBCA_PROGRESS : 30%
# DBCA_PROGRESS : 31%
# DBCA_PROGRESS : 34%
# DBCA_PROGRESS : 38%
# DBCA_PROGRESS : 41%
# DBCA_PROGRESS : 43%
# [ 2019-03-14 20:52:47.935 EET ] Completing Database Creation
# DBCA_PROGRESS : 47%
# DBCA_PROGRESS : 50%
# [ 2019-03-14 21:02:11.215 EET ] Creating Pluggable Databases
# DBCA_PROGRESS : 54%
# DBCA_PROGRESS : 71%
# [ 2019-03-14 21:03:10.672 EET ] Executing Post Configuration Actions
# DBCA_PROGRESS : 93%
# [ 2019-03-14 21:03:10.676 EET ] Running Custom Scripts
# DBCA_PROGRESS : 100%
# [ 2019-03-14 21:03:16.553 EET ] Database creation complete. For details check the logfiles at:
#  /opt/oracle/cfgtoollogs/dbca/XE.
# Database Information:
# Global Database Name:XE
# System Identifier(SID):XE

# now oracle database listens on port 1521
netstat -tulpn | grep 1521

systemctl status oracle-xe-18c
systemctl enable oracle-xe-18c
systemctl start oracle-xe-18c


# install instant client
# https://www.oracle.com/technetwork/topics/linuxx86-64soft-092277.html

# https://download.oracle.com/otn/linux/instantclient/183000/oracle-instantclient18.3-basic-18.3.0.0.0-3.x86_64.rpm?AuthParam=1552592336_1718665abe5b0c48d71858d5fa869dca
# https://download.oracle.com/otn/linux/instantclient/183000/oracle-instantclient18.3-odbc-18.3.0.0.0-3.x86_64.rpm?AuthParam=1552592399_e99b60e7a2d44c2f7cb70961d6b1e2f9


rpm -i oracle-instantclient18.3-basic-18.3.0.0.0-3.x86_64.rpm # required for odbc 
rpm -i oracle-instantclient18.3-odbc-18.3.0.0.0-3.x86_64.rpm # odbc connector. needed to use direct SQL statements


echo "/u01/app/oracle/product/11.2.0/xe/lib" > /etc/ld.so.conf.d/oracle.conf
chmod o+r /etc/ld.so.conf.d/oracle.conf

ls -l /etc/ld.so.conf.d
ls -l /usr/lib/oracle/18.3/client64/lib
echo "/usr/lib/oracle/18.3/client64/lib" > /etc/ld.so.conf.d/oracle-client-18.3.conf
ldconfig -v
# chmod o+r /etc/ld.so.conf.d/oracle-client-18.3.conf

