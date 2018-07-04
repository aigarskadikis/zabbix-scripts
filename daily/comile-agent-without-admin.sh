yum -y install wget gcc

cd

dir=~/custom
mkdir -p $dir
cd $dir
wget https://sourceforge.net/projects/pcre/files/pcre/8.38/pcre-8.38.tar.gz
tar -vzxf pcre-8.38.tar.gz
export PATH="/usr/bin:/bin:/usr/sbin:/sbin:/usr/sfw/bin:/usr/ccs/bin"
cd $dir/pcre-8.38
./configure --prefix=$dir/env --disable-cpp --disable-shared --enable-utf8 --enable-unicode-properties
time make install

tree $dir/env

