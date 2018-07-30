
# allow apt-get to be used
rm /var/lib/apt/lists/lock

# update repos
apt-get -y update

# install postfix mail server
apt-get -y install logcheck

# if i got to error:
# E: Could not get lock /var/lib/dpkg/lock - open (11: Resource temporarily unavailable)
# E: Unable to lock the administration directory (/var/lib/dpkg/), is another process using it?
# then wait a minure and try again

find / -name externalscripts

# move to external scripts dir
cd /usr/lib/zabbix/externalscripts

# download file:
wget https://raw.githubusercontent.com/oscm/zabbix/master/postfix/postfix

# ubuntu keeps the log in a bit different format
sed -i "s/maillog/mail.log/g" postfix

# set file executable
chmod +x postfix

# set the right owner
chown zabbix. postfix

# check if something works
./postfix discovery

# move to agent userparameter dir
cd /etc/zabbix/zabbix_agentd.d

# download userparameter instructions
wget https://raw.githubusercontent.com/oscm/zabbix/master/postfix/userparameter_postfix.conf

# set postfix location to /usr/lib/zabbix/externalscripts
sed -i "s/\/srv\/zabbix\/libexec/\/usr\/lib\/zabbix\/externalscripts/g" userparameter_postfix.conf 

# make sure the log is there
ls -l /var/log/mail.log
# if the log is not there then stop processing further steps

# allow 'zabbix' user to read the log
usermod -a -G adm zabbix

# restart agent
systemctl restart zabbix-agent