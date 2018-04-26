#!/bin/bash
#https://www.digitalocean.com/community/tutorials/how-to-install-and-configure-grafana-to-plot-beautiful-graphs-from-zabbix-on-centos-7

#install grafana repo
echo "W2dyYWZhbmFdCm5hbWU9Z3JhZmFuYQpiYXNldXJsPWh0dHBzOi8vcGFja2FnZWNsb3VkLmlvL2dyYWZhbmEvc3RhYmxlL2VsLzYvJGJhc2VhcmNoCnJlcG9fZ3BnY2hlY2s9MQplbmFibGVkPTEKZ3BnY2hlY2s9MQpncGdrZXk9aHR0cHM6Ly9wYWNrYWdlY2xvdWQuaW8vZ3BnLmtleSBodHRwczovL2dyYWZhbmFyZWwuczMuYW1hem9uYXdzLmNvbS9SUE0tR1BHLUtFWS1ncmFmYW5hCnNzbHZlcmlmeT0xCnNzbGNhY2VydD0vZXRjL3BraS90bHMvY2VydHMvY2EtYnVuZGxlLmNydAoK" | base64 --decode > /etc/yum.repos.d/grafana.repo
cat /etc/yum.repos.d/grafana.repo

#install GPG key
cd /etc/pki/rpm-gpg
curl -s -O https://grafanarel.s3.amazonaws.com/RPM-GPG-KEY-grafana
rpm --import RPM-GPG-KEY-grafana

yum install grafana -y
systemctl daemon-reload
systemctl start grafana-server
systemctl enable grafana-server
grafana-cli plugins install alexanderzobnin-zabbix-app

systemctl restart grafana-server

#make sure the port 3000 is listening
netstat -tulpn

firewall-cmd --add-port=3000/tcp --permanent
firewall-cmd --reload

#http://localhost/zabbix/api_jsonrpc.php
