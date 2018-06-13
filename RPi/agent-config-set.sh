#!/bin/bash

#define a conf file variable
agent=/usr/local/etc/zabbix_agentd.conf

grep "^PidFile=" $agent
if [ "$?" -eq "0" ]; then
sed -i "s|^PidFile=.*$|PidFile=\/dev\/shm\/zabbix_agentd.pid|" $agent
else
ln=$(grep -n "PidFile=" $agent | egrep -o "^[0-9]+"); ln=$((ln+1))
sed -i "`echo $ln`iPidFile=\/dev\/shm\/zabbix_agentd.pid" $agent
fi

grep "^LogFile=" $agent
if [ "$?" -eq "0" ]; then
sed -i "s|^LogFile=.*$|LogFile=\/dev\/shm\/zabbix_agentd.log|" $agent
else
ln=$(grep -n "LogFile=" $agent | egrep -o "^[0-9]+"); ln=$((ln+1))
sed -i "`echo $ln`iLogFile=\/dev\/shm\/zabbix_agentd.log" $agent
fi

grep "^EnableRemoteCommands=" $agent
if [ "$?" -eq "0" ]; then
sed -i "s|^EnableRemoteCommands=.*$|EnableRemoteCommands=1|" $agent
else
ln=$(grep -n "EnableRemoteCommands=" $agent | egrep -o "^[0-9]+"); ln=$((ln+1))
sed -i "`echo $ln`iEnableRemoteCommands=1" $agent
fi

grep "^LogRemoteCommands=" $agent
if [ "$?" -eq "0" ]; then
sed -i "s|^LogRemoteCommands=.*$|LogRemoteCommands=1|" $agent
else
ln=$(grep -n "LogRemoteCommands=" $agent | egrep -o "^[0-9]+"); ln=$((ln+1))
sed -i "`echo $ln`iLogRemoteCommands=1" $agent
fi

grep "^Server=" $agent
if [ "$?" -eq "0" ]; then
sed -i "s|^Server=.*$|Server=$1|" $agent
else
ln=$(grep -n "Server=$" $agent | egrep -o "^[0-9]+"); ln=$((ln+1))
sed -i "`echo $ln`iServer=$1" $agent
fi

grep "^ServerActive=" $agent
if [ "$?" -eq "0" ]; then
sed -i "s|^ServerActive=.*$|ServerActive=$1|" $agent
else
ln=$(grep -n "ServerActive=$" $agent | egrep -o "^[0-9]+"); ln=$((ln+1))
sed -i "`echo $ln`iServerActive=$1" $agent
fi

#delete the static host name
sed -i '/^Hostname=.*$/d' $agent

#set hostname based on the lan mac
com="system.run\[ifconfig eth0\|egrep -o \"..:..:.. \"\|sed \"s\|:\|\|g;s\|^\|RPiWorK\|\"\]"
grep "^HostMetadataItem=" $agent
if [ "$?" -eq "0" ]; then
sed -i "s|^HostMetadataItem=.*$|HostMetadataItem=$com|" $agent
else
ln=$(grep -n "HostMetadataItem=" $agent | egrep -o "^[0-9]+"); ln=$((ln+1))
sed -i "`echo $ln`iHostMetadataItem=$com" $agent
fi


#enable Include=/usr/local/etc/zabbix_agentd.conf.d/*.conf
sed -i "s|^.*Include=\/usr\/local\/etc\/zabbix_agentd.conf.d\/\*.conf$|Include=\/usr\/local\/etc\/zabbix_agentd.conf.d\/\*.conf|" $agent
