#update system
yum update -y

base=2.4
minor=5

#install mysql server
yum install mariadb-server -y

#start mysql server
systemctl start mariadb
echo $?

#set root password
/usr/bin/mysqladmin -u root password '5sRj4GXspvDKsBXW'
echo $?

#list existing databases
mysql -h localhost -uroot -p5sRj4GXspvDKsBXW -P 3306 -s <<< 'show databases;'
echo $?

#create new database
mysql -h localhost -uroot -p5sRj4GXspvDKsBXW -P 3306 -s <<< 'create database zabbix_proxy character set utf8 collate utf8_bin;'
echo $?

#create use for mysql and assign to database
mysql -h localhost -uroot -p5sRj4GXspvDKsBXW -P 3306 -s <<< 'grant all privileges on zabbix_proxy.* to zabbix@localhost identified by "TaL2gPU5U9FcCU2u";'
echo $?

mysql -h localhost -uroot -p5sRj4GXspvDKsBXW -P 3306 -s <<< 'flush privileges;'
echo $?

mysql -h localhost -uroot -p5sRj4GXspvDKsBXW -P 3306 -s <<< 'show databases;'
echo $?

#enable mysql at startup
systemctl enable mariadb
echo $?

#install zabbix repo
rpm -ivh http://repo.zabbix.com/zabbix/$base/rhel/7/x86_64/zabbix-release-$base-1.el7.noarch.rpm
rpm -ivh http://repo.zabbix.com/zabbix/$base/rhel/7/x86_64/zabbix-release-$base-2.el7.noarch.rpm
echo $?

#reroad repo content
yum update -y
echo $?

#install zabbix proxy
yum install zabbix-proxy-mysql -y
echo $?
#this package creates user zabbix
grep zabbix /etc/passwd

#create basic database schema
ls -l /usr/share/doc/zabbix-proxy-mysql*/
zcat /usr/share/doc/zabbix-proxy-mysql*/schema.sql.gz | mysql -uzabbix -pTaL2gPU5U9FcCU2u zabbix_proxy

grep "DBPassword=" /etc/zabbix/zabbix_proxy.conf
sed -i "s/^.*DBPassword=.*$/DBPassword=TaL2gPU5U9FcCU2u/g" /etc/zabbix/zabbix_proxy.conf
grep -v "^$\|^#" /etc/zabbix/zabbix_proxy.conf

#check startup status of zabbix and mariadb
systemctl list-unit-files | grep "zabbix\|mariadb"

systemctl status zabbix-proxy

systemctl enable zabbix-proxy

systemctl start zabbix-proxy

cat /var/log/zabbix/zabbix_proxy.log
#cannot set resource limit: [13] Permission denied

yum install policycoreutils-python -y
grep "denied.*zabbix.*proxy" /var/log/audit/audit.log | audit2allow -M zabbix_proxy
semodule -i zabbix_proxy.pp

systemctl enable zabbix-proxy

sed -i "s/^Server=.*$/Server=5d61050b753b.sn.mynetname.net/g" /etc/zabbix/zabbix_proxy.conf
sed -i "s/^Hostname=.*$/Hostname=CentProxy/g" /etc/zabbix/zabbix_proxy.conf
grep -v "^$\|^#" /etc/zabbix/zabbix_proxy.conf

systemctl stop zabbix-proxy
sleep 1
> /var/log/zabbix/zabbix_proxy.log
sleep 1
systemctl start zabbix-proxy
sleep 1
cat /var/log/zabbix/zabbix_proxy.log

#set up encryption
mkdir -p /home/zabbix
openssl rand -hex 32 > /home/zabbix/proxy.psk
chmod 600 /home/zabbix/proxy.psk
chown -R zabbix:zabbix /home/zabbix
sed -i "s/^.*TLSConnect=.*$/TLSConnect=psk/g" /etc/zabbix/zabbix_proxy.conf
sed -i "s/^.*TLSAccept=.*$/TLSAccept=psk/g" /etc/zabbix/zabbix_proxy.conf
sed -i "s/^.*TLSPSKIdentity=.*$/TLSPSKIdentity=PSK002/g" /etc/zabbix/zabbix_proxy.conf
sed -i "s/^.*TLSPSKFile=.*$/TLSPSKFile=\/home\/zabbix\/proxy.psk/g" /etc/zabbix/zabbix_proxy.conf
grep -v "^$\|^#" /etc/zabbix/zabbix_proxy.conf
cat /home/zabbix/proxy.psk

systemctl stop zabbix-proxy
sleep 1
> /var/log/zabbix/zabbix_proxy.log
sleep 1
systemctl start zabbix-proxy
sleep 1
grep "denied.*proxy.psk" /var/log/audit/audit.log | audit2allow -M zabbix_proxy_psk_read
semodule -i zabbix_proxy_psk_read.pp

tail -f /var/log/zabbix/zabbix_proxy.log

#if you receive 
#Unable to connect to the server [zabbix.server.name]:10051 [cannot connect to [[zabbix.server.name]:10051]: [13] Permission denied]
#then install again selinux policies
grep "denied.*zabbix.*proxy" /var/log/audit/audit.log | audit2allow -M zabbix_proxy
semodule -i zabbix_proxy.pp
