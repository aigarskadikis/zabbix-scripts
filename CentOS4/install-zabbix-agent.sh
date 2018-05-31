#http://vault.centos.org/4.9/isos/i386/CentOS-4.8-i386-binDVD.torrent

#getting CentOS 4 repo to work
cp /etc/yum.repos.d/CentOS-Base.repo ~ #backup original repo
curl http://vault.centos.org/4.8/CentOS-Base.repo > /etc/yum.repos.d/CentOS-Base.repo #overwrite original

yum update
cd
wget --no-check-certificate http://downloads.sourceforge.net/project/zabbix/ZABBIX%20Latest%20Stable/3.0.17/zabbix-3.0.17.tar.gz
tar -vzxf zabbix-*.tar.gz -C .
cd zabbix-*
./configure --enable-agent

time make install

grep -v "^$\|^#" /usr/local/etc/zabbix_agentd.conf

sed -i "s/^Server=.*/Server=10.0.2.5/" /usr/local/etc/zabbix_agentd.conf
sed -i "s/^ServerActive=.*/ServerActive=10.0.2.5/" /usr/local/etc/zabbix_agentd.conf
sed -i "s/^Hostname=.*/Hostname=CentOS4/" /usr/local/etc/zabbix_agentd.conf

grep -v "^$\|^#" /usr/local/etc/zabbix_agentd.conf

groupadd zabbix
useradd -g zabbix zabbix

#take init script from old version
cd
wget --no-check-certificate http://downloads.sourceforge.net/project/zabbix/ZABBIX%20Latest%20Stable/1.8.20/zabbix-1.8.20.tar.gz
tar -vzxf zabbix-1.8.20.tar.gz -C .
cat ~/zabbix-1.8.20/misc/init.d/redhat/zabbix_agentd_ctl > /etc/init.d/zabbix-agent
#set the base and pid according to system
# base zabbix dir
#BASEDIR=/usr/local
# pid file (as of 1.0 beta 10)
#PIDFILE=/tmp/zabbix_agentd.pid
sed -i "s/^BASEDIR=.*/BASEDIR=\/usr\/local/" /etc/init.d/zabbix-agent
sed -i "s/^PIDFILE=.*/PIDFILE=\/tmp\/zabbix_agentd.pid/" /etc/init.d/zabbix-agent
chmod +x /etc/init.d/zabbix-agent

