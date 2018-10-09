# pcre
yum -y install gcc gcc-c++ libtool
mkdir -p /tmp/zabbix_agent
cd /tmp/zabbix_agent
wget --no-check-certificate https://ftp.pcre.org/pub/pcre/pcre-8.41.tar.gz
tar -vzxf pcre-8.41.tar.gz -C .
cd pcre-8.41
./configure CC="gcc" --prefix=/tmp/zabbix_agent/env --disable-cpp --disable-shared --enable-utf8 --enable-unicode-properties
time make
ls -1 /tmp/zabbix_agent/env
make install
ls -1 /tmp/zabbix_agent/env

# libiconv
cd /tmp/zabbix_agent
wget http://ftp.gnu.org/pub/gnu/libiconv/libiconv-1.15.tar.gz
tar -vzxf libiconv-1.15.tar.gz -C .
cd libiconv-1.15
./configure --enable-static --enable-shared=no --prefix=/tmp/zabbix_agent/env
time make
libtool --finish /tmp/zabbix_agent/env/lib

# perl [required to compile ssl]
cd /tmp/zabbix_agent
wget http://www.cpan.org/src/5.0/perl-5.28.0.tar.gz
tar -vzxf perl-5.28.0.tar.gz -C .
cd perl-5.28.0
./configure.gnu --prefix=/tmp/zabbix_agent/perl
time make
time make test # this will tike like 20 minutes or something
make install

# ssl

wget https://www.openssl.org/source/openssl-1.1.0i.tar.gz
tar -vzxf openssl-1.1.0i.tar.gz -C .
cd openssl-1.1.0i
./config
./Configure no-shared no-threads --prefix=/tmp/zabbix_agent/env linux-x86
time make



# zabbix agent
cd /tmp/zabbix_agent
zabbixagentver=3.4.14
wget --no-check-certificate http://downloads.sourceforge.net/project/zabbix/ZABBIX%20Latest%20Stable/$zabbixagentver/zabbix-$zabbixagentver.tar.gz
tar -vzxf zabbix-$zabbixagentver.tar.gz -C .
cd zabbix-$zabbixagentver
./configure --enable-agent --prefix=/ --sysconfdir=/etc/zabbix \
    --with-libpcre=/tmp/zabbix_agent/env \
    --with-iconv=/tmp/zabbix_agent/env
	
time make
make install

	
	