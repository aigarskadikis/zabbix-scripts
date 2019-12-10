#!/bin/bash

# on RHEL7/CentOS7
yum -y install epel-release
 
# depenencies for ServiceNow module
yum -y install perl-MIME-Types
yum -y install perl-SOAP-Lite
yum -y install perl-JSON-RPC
yum -y install perl-JSON-XS
yum -y install perl-Log-Log4perl
yum -y install perl-LWP-Protocol-https

# allow to compile new perl module
yum -y install perl-devel
 
cd ServiceNow-Perl-API
 
perl Makefile.PL
# warnings will be on screen
 
make
 
# for next command to succeed its required to have
yum -y install perl-Test-use-ok
make test
# othervise some major errors will be on screen, but thats OK
 
make install

cd ..

# install service now script
cat zservicenow-na.pl > /usr/lib/zabbix/alertscripts/zservicenow-na
# set script executable and read only
chmod 500 /usr/lib/zabbix/alertscripts/zservicenow-na

# alert scripts direcotry in general should belong to user 'zabbix'
chown zabbix. -R /usr/lib/zabbix/alertscripts

cd /usr/lib/zabbix/alertscripts
./zservicenow-na

cat /var/log/zabbix/zabbix_servicenow_na.log
# should print 'zservicenow-na 59 Usage error'
