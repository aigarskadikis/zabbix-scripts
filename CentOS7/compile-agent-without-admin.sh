yum -y install wget gcc

cd

dir=~/custom
mkdir -p $dir
cd $dir
wget https://sourceforge.net/projects/pcre/files/pcre/8.38/pcre-8.38.tar.gz
tar -vzxf pcre-8.38.tar.gz
export PATH="/usr/bin:/bin:/usr/sbin:/sbin:/usr/sfw/bin:/usr/ccs/bin"
cd $dir/pcre-8.38
./configure --help
./configure --prefix=$dir/env --disable-cpp --disable-shared --enable-utf8 --enable-unicode-properties
time make install

tree $dir/env




cd $dir
wget https://www.openssl.org/source/openssl-1.0.2o.tar.gz
tar -vzxf openssl-1.0.2o.tar.gz
export PATH="/usr/bin:/bin:/usr/sbin:/sbin:/usr/sfw/bin:/usr/ccs/bin"
cd $dir/openssl-1.0.2o
./Configure --help
./Configure no-shared no-threads --prefix=$dir/env dist

time make install

tree $dir/env

cd $dir
wget http://downloads.sourceforge.net/project/zabbix/ZABBIX%20Latest%20Stable/3.4.11/zabbix-3.4.11.tar.gz
tar -vzxf zabbix-3.4.11.tar.gz
cd $dir/zabbix-3.4.11
dest=~/agent
mkdir -p $dest
./configure --enable-agent --prefix=$dest -with-openssl=$dir/env -with-libpcre=$dir/env
time make install

cd ~/agent


