
cd /usr/lib/zabbix/

rm externalscripts -rf

git clone git@github.com:catonrug/externalscripts.git

chown -R zabbix:zabbix externalscripts

cd externalscripts

chmod 770 *

#install jq support for show-isp.sh to work
curl -sL https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64 -o /usr/bin/jq
chmod +x /usr/bin/jq

