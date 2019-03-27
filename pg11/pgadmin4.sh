#!/bin/bash

# from http://yallalabs.com/linux/how-to-install-pgadmin-4-in-server-mode-as-web-application-on-centos-7-rhel-7/

yum -y install epel-release

yum -y install pgadmin4

# go to directory where 'config_distro.py' and 'setup.py' is installed
cd $(find / -name pgadmin4-web)

# set where the sqlite3 database is located
cat << 'EOF' > config_distro.py
HELP_PATH = '/usr/share/doc/pgadmin4-docs/en_US/html'
UPGRADE_CHECK_ENABLED = False
LOG_FILE = '/var/log/pgadmin4/pgadmin4.log'
SQLITE_PATH = '/var/lib/pgadmin4/pgadmin4.db'
SESSION_DB_PATH = '/var/lib/pgadmin4/sessions'
STORAGE_DIR = '/var/lib/pgadmin4/storage'

EOF


rm -rf /var/lib/pgadmin4/pgadmin4.db

python setup.py

# enter 'x@y.zz' for username and passowrd
# after 10 seconds it will say:
# pgAdmin 4 - Application Initialisation
# ======================================

getenforce
# Change the ownership of the configuration database directory to the user Apache
grep apache /etc/passwd
chown -R apache:apache /var/lib/pgadmin4
chown -R apache:apache /var/log/pgadmin4

# If the SeLinux is enabled, adjust the SELinux policy using the following commands
chcon -R -t httpd_sys_content_rw_t "/var/log/pgadmin4/"
chcon -R -t httpd_sys_content_rw_t "/var/lib/pgadmin4/"

# frontend conf
cd /etc/httpd/conf.d/

cat << 'EOF' > pgadmin4.conf
WSGIDaemonProcess pgadmin processes=1 threads=25
WSGIScriptAlias /pgadmin4 /usr/lib/python2.7/site-packages/pgadmin4-web/pgAdmin4.wsgi

<Directory /usr/lib/python2.7/site-packages/pgadmin4-web/>
        WSGIProcessGroup pgadmin
        WSGIApplicationGroup %{GLOBAL}
        <IfModule mod_authz_core.c>
                # Apache 2.4
                Require all granted
        </IfModule>
        <IfModule !mod_authz_core.c>
                # Apache 2.2
                Order Deny,Allow
                Allow from All
#               Allow from 127.0.0.1
#               Allow from ::1
        </IfModule>
</Directory>

EOF

# check the apache configuration
apachectl configtest

# To make sure PgAdmin can access to the PostgreSQL server we need to adjust Selinux to allow Apache to connect via network using the following command
setsebool -P httpd_can_network_connect 1

# firewall conf
firewall-cmd --permanent --add-service=http
firewall-cmd --reload


systemctl restart httpd

# go to http://ip.add.goes.here/pgadmin4/
# write down
# username: x@y.zz
# password: x@y.zz


# Create a new server name "first", go to second tab "Connections" enter:
# Host: 127.0.0.1



find / -name pg_dump


