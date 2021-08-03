#!/bin/bash

# instruction based on thread:
# https://gist.github.com/jeanlescure/084dd6113931ea5a0fd9

# sequence tested on "Ubuntu 20.04.2 LTS"

# download zabbix repo
wget https://repo.zabbix.com/zabbix/5.0/ubuntu/pool/main/z/zabbix-release/zabbix-release_5.0-1+focal_all.deb
# install zabbix repo
dpkg -i zabbix-release_5.0-1+focal_all.deb

# install prerequisites to create an offline repository
apt-get update && apt-get install -y apt-rdepends dpkg-dev gzip genisoimage

# create a working directory '/repo' that will hold the scripts which will create an offline repository
# '/repo/offline' will contain all packages
mkdir -p /repo/offline

# because 'apt' utility runs behind a dedicated service user it's better to set the working directory be owned by user '_apt'
chown _apt -R /repo

# navigate to user '_apt'
su - _apt -s /bin/bash
# it will say:
# su: warning: cannot change directory to /nonexistent: No such file or directory
# that is fine

# enter directory where scripts will be located
cd /repo

# create a script which will download all dependencies
echo "IyEvdXNyL2Jpbi9lbnYgYmFzaAoKZnVuY3Rpb24gZXJyb3JfZXhpdAp7CiAgZWNobyAiJDEiIDE+JjIKICBlY2hvICJVc2FnZTogLi9nZXRwa2cuc2ggPHBhY2thZ2UtbmFtZT4gPHBhY2thZ2VzLWRpcmVjdG9yeT4iIDE+JjIKICBleGl0IDEKfQoKUEtHPSIkMSIKUEtHRElSPSIkMiIKCmlmIFsgLXogIiRQS0ciIF07IHRoZW4KICBlcnJvcl9leGl0ICJObyBwYWNrYWdlIG5hbWUgc2V0ISIKZmkKCmlmIFsgLXogIiRQS0dESVIiIF07IHRoZW4KICBlcnJvcl9leGl0ICJObyBwYWNrYWdlcyBkaXJlY3RvcnkgcGF0aCBzZXQhIgpmaQoKY2QgJFBLR0RJUgoKZm9yIGkgaW4gJChhcHQtcmRlcGVuZHMgJFBLR3xncmVwIC12ICJeICIpCiAgZG8gISBhcHQtZ2V0IGRvd25sb2FkICRpCmRvbmUK" | base64 --decode > getpkg.sh
# set script executable
chmod +x getpkg.sh


# request to download a base package. this will download all dependencies too.
./getpkg.sh mysql-server offline ; ./getpkg.sh zabbix-server-mysql offline ; ./getpkg.sh zabbix-frontend-php offline ; ./getpkg.sh zabbix-nginx-conf offline ; ./getpkg.sh zabbix-agent offline ; ./getpkg.sh zabbix-agent2 offline ; ./getpkg.sh zabbix-proxy-sqlite3 offline ; ./getpkg.sh zabbix-get offline ; ./getpkg.sh zabbix-sender offline ; ./getpkg.sh zabbix-js offline ; ./getpkg.sh zabbix-java-gateway offline
# wait 5 minutes
# during the time, it will print:
# Can't select candidate version from package debconf-2.0 as it has no candidate
# that is fine

# create a script which will contain data which packages are available in this offline repository.
echo "IyEvdXNyL2Jpbi9lbnYgYmFzaAoKZnVuY3Rpb24gZXJyb3JfZXhpdAp7CiAgZWNobyAiJDEiIDE+JjIKICBlY2hvICJVc2FnZTogLi9ta3JlcG8uc2ggPHBhY2thZ2VzLWRpcmVjdG9yeT4iIDE+JjIKICBleGl0IDEKfQoKUEtHRElSPSIkMSIKCmlmIFsgLXogIiRQS0dESVIiIF07IHRoZW4KICBlcnJvcl9leGl0ICJObyBwYWNrYWdlcyBkaXJlY3RvcnkgcGF0aCBzZXQhIgpmaQoKY2QgJFBLR0RJUgoKZHBrZy1zY2FucGFja2FnZXMgLi8gL2Rldi9udWxsIHwgZ3ppcCAtOWMgPiAuL1BhY2thZ2VzLmd6Cg==" | base64 --decode > mkrepo.sh
# set script executable
chmod +x mkrepo.sh

# make sure you are located in /repo
cd /repo
# create 
./mkrepo.sh offline
# dpkg-scanpackages: warning: Packages in archive but missing from override file:
# dpkg-scanpackages: warning:   adduser ca-certificates ca-certificates-java cdebconf coreutils debconf debianutils default-jre-headless default-mysql-client dpkg fontconfig-config fonts-dejavu fonts-dejavu-core fonts-dejavu-extra fonts-liberation fping gcc-10-base install-info iproute2 java-common libacl1 libaio1 libapparmor1 libargon2-1 libasn1-8-heimdal libasound2 libasound2-data libattr1 libaudit-common libaudit1 libavahi-client3 libavahi-common-data libavahi-common3 libblkid1 libbrotli1 libbsd0 libbz2-1.0 libc6 libcap-ng0 libcap2 libcap2-bin libcom-err2 libcrypt1 libcryptsetup12 libcups2 libcurl4 libdb5.3 libdbus-1-3 libdebian-installer4 libdevmapper1.02.1 libedit2 libelf1 libevent-2.1-7 libevent-core-2.1-7 libevent-pthreads-2.1-7 libexpat1 libffi7 libfontconfig1 libfreetype6 libgcc-s1 libgcrypt20 libgd3 libgdbm-compat4 libgdbm6 libgeoip1 libglib2.0-0 libgmp10 libgnutls30 libgpg-error0 libgraphite2-3 libgssapi-krb5-2 libgssapi3-heimdal libharfbuzz0b libhcrypto4-heimdal libheimbase1-heimdal libheimntlm0-heimdal libhiredis0.14 libhogweed5 libhx509-5-heimdal libicu66 libidn2-0 libip4tc2 libjbig0 libjpeg-turbo8 libjpeg8 libjson-c4 libk5crypto3 libkeyutils1 libkmod2 libkrb5-26-heimdal libkrb5-3 libkrb5support0 liblcms2-2 libldap-2.4-2 libldap-common libltdl7 libluajit-5.1-2 libluajit-5.1-common liblz4-1 liblzma5 libmagic-mgc libmagic1 libmaxminddb0 libmecab2 libmnl0 libmount1 libmysqlclient21 libnettle7 libnewt0.52 libnghttp2-14 libnginx-mod-http-auth-pam libnginx-mod-http-cache-purge libnginx-mod-http-dav-ext libnginx-mod-http-echo libnginx-mod-http-fancyindex libnginx-mod-http-geoip libnginx-mod-http-geoip2 libnginx-mod-http-headers-more-filter libnginx-mod-http-image-filter libnginx-mod-http-lua libnginx-mod-http-ndk libnginx-mod-http-perl libnginx-mod-http-subs-filter libnginx-mod-http-uploadprogress libnginx-mod-http-upstream-fair libnginx-mod-http-xslt-filter libnginx-mod-mail libnginx-mod-nchan libnginx-mod-stream libnspr4 libnss3 libnuma1 libodbc1 libonig5 libopenipmi0 libp11-kit0 libpam-modules libpam-modules-bin libpam-runtime libpam0g libpci3 libpcre2-8-0 libpcre3 libpcsclite1 libperl5.30 libpng16-16 libpq5 libpsl5 libreadline8 libroken18-heimdal librtmp1 libsasl2-2 libsasl2-modules-db libseccomp2 libselinux1 libsemanage-common libsemanage1 libsensors-config libsensors5 libsepol1 libslang2 libsmartcols1 libsnmp-base libsnmp35 libsodium23 libsqlite3-0 libssh-4 libssl1.1 libstdc++6 libsystemd0 libtasn1-6 libtextwrap1 libtiff5 libtinfo6 libudev1 libunistring2 libuuid1 libwebp6 libwind0-heimdal libwrap0 libx11-6 libx11-data libxau6 libxcb1 libxdmcp6 libxml2 libxpm4 libxslt1.1 libxtables12 libzstd1 login lsb-base mime-support mount mysql-client mysql-client-8.0 mysql-client-core-8.0 mysql-common mysql-server mysql-server-8.0 mysql-server-core-8.0 netbase nginx nginx-common nginx-core nginx-extras nginx-full nginx-light openjdk-11-jre-headless openssl passwd pci.ids perl perl-base perl-modules-5.30 php-bcmath php-common php-fpm php-gd php-ldap php-mbstring php-mysql php-pgsql php-xml php7.4-bcmath php7.4-cli php7.4-common php7.4-fpm php7.4-gd php7.4-json php7.4-ldap php7.4-mbstring php7.4-mysql php7.4-opcache php7.4-pgsql php7.4-readline php7.4-xml psmisc readline-common sed sensible-utils sqlite3 systemd systemd-timesyncd tar ttf-bitstream-vera ttf-dejavu-core tzdata ucf util-linux zabbix-agent zabbix-agent2 zabbix-frontend-php zabbix-get zabbix-java-gateway zabbix-js zabbix-nginx-conf zabbix-proxy-sqlite3 zabbix-sender zabbix-server-mysql zlib1g
# dpkg-scanpackages: info: Wrote 261 entries to output Packages file.

# create ISO file
mkisofs -J -l -R -V "Zabbix" -iso-level 4 -o /tmp/zabbix-offline-install-ubuntu20.iso /repo/offline
# size of iso will be ~135M

# exit user '_apt'
exit

# use WinSCP and download '/tmp/zabbix-offline-install-ubuntu20.iso'
