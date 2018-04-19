
cd /usr/lib/zabbix/

rm externalscripts -rf

git clone git@github.com:catonrug/externalscripts.git

chown -R zabbix:zabbix externalscripts

cd externalscripts

chmod 770 *

