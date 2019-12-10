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
# warning will be on screen
 
make
 
# for next command to succeed its required to have
yum -y install perl-Test-use-ok
make test
# othervise some major errors will be on screen, but thats OK
 
make install

cd ..
