#!/bin/bash


maj=5.0
min=2

cd /dev/shm

curl -L "https://cdn.zabbix.com/zabbix/sources/stable/$maj/zabbix-$maj.$min.tar.gz" -o zabbix-$maj.$min.tar.gz

tar -vzxf zabbix-$maj.$min.tar.gz

cd zabbix-$maj.$min

./configure --enable-agent

make install > /dev/shm/out.log

#  --bindir=DIR            user executables [EPREFIX/bin]
#  --sbindir=DIR           system admin executables [EPREFIX/sbin]
#  --libexecdir=DIR        program executables [EPREFIX/libexec]
#  --sysconfdir=DIR        read-only single-machine data [PREFIX/etc]

./configure --sysconfdir=/etc/zabbix --prefix=/usr --enable-proxy --enable-agent --with-sqlite3 --with-libcurl --with-libxml2 --with-ssh2 --with-net-snmp --with-openssl --with-unixodbc 

./configure --sysconfdir=/etc/zabbix --prefix=/usr --enable-proxy --enable-agent --enable-agent2 --with-sqlite3 --with-libcurl --with-libxml2 --with-ssh2 --with-net-snmp --with-openssl --with-unixodbc 

./configure --sysconfdir=/etc/zabbix --prefix=/usr --enable-proxy --enable-agent --enable-agent2 --with-sqlite3 --with-libcurl --with-libxml2 --with-ssh2 --with-net-snmp --with-openssl --with-unixodbc --enable-java

# configure: error: no acceptable C compiler found in $PATH
sudo apt -y install build-essential

# configure: error: SQLite3 library not found
sudo apt -y install libsqlite3-dev

# configure: error: LIBXML2 library not found
sudo apt -y install libxml2-dev pkg-config

# configure: error: unixODBC library not found
sudo apt -y install unixodbc-dev

# configure: error: Invalid Net-SNMP directory - unable to find net-snmp-config
sudo apt -y install libsnmp-dev

# configure: error: SSH2 library not found
sudo apt -y install libssh2-1-dev

# configure: error: Unable to use libevent (libevent check failed)
sudo apt -y install libevent-dev

# configure: error: Curl library not found
sudo apt -y install libcurl4-openssl-dev

# configure: error: Unable to use libpcre (libpcre check failed)
sudo apt -y install libpcre3-dev

# configure: error: Unable to find "go" executable in path
sudo apt -y install golang

# configure: error: Unable to find "javac" executable in path
sudo apt -y install openjdk-8-jdk


# install services
# http://repo.zabbix.com/zabbix/5.0/ubuntu/pool/main/z/zabbix/zabbix-proxy-sqlite3_5.0.2-1%2Bfocal_amd64.deb


# instll init.d
cd /etc/init.d
cat << 'EOF' > zabbix-proxy
#! /bin/sh
### BEGIN INIT INFO
# Provides:          zabbix-proxy
# Required-Start:    $remote_fs $network 
# Required-Stop:     $remote_fs
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Start zabbix-proxy daemon
### END INIT INFO

set -e

NAME=zabbix_proxy
DAEMON=/usr/sbin/$NAME
DESC="Zabbix proxy daemon"

test -x $DAEMON || exit 0

DIR=/run/zabbix
PID=$DIR/$NAME.pid
RETRY=15

if test ! -d "$DIR"; then
  mkdir -p "$DIR"
  chown -R zabbix:zabbix "$DIR"
fi

export PATH="${PATH:+$PATH:}/usr/sbin:/sbin"

# define LSB log_* functions.
. /lib/lsb/init-functions

if [ -r "/etc/default/zabbix-proxy" ]; then
    . /etc/default/zabbix-proxy
fi

case "$1" in
  start)
    log_daemon_msg "Starting $DESC" "$NAME"
    start-stop-daemon --oknodo --start --pidfile $PID \
      --exec $DAEMON >/dev/null 2>&1
    case "$?" in
        0) log_end_msg 0 ;;
        *) log_end_msg 1; exit 1 ;;
    esac
    ;;
  stop)
    log_daemon_msg "Stopping $DESC" "$NAME"
    start-stop-daemon --oknodo --stop --pidfile $PID --retry $RETRY
    case "$?" in
        0) log_end_msg 0 ;;
        *) log_end_msg 1; exit 1 ;;
    esac
    ;;
  status)
    status_of_proc -p "$PID" "$DAEMON" "$NAME" && exit 0 || exit $?
    ;;
  restart|force-reload)
    $0 stop
    $0 start
    ;;
  *)
    echo "Usage: $0 {start|stop|restart|force-reload}" >&2
    exit 1
    ;;
esac

exit 0

EOF

# or
# echo "IyEgL2Jpbi9zaAojIyMgQkVHSU4gSU5JVCBJTkZPCiMgUHJvdmlkZXM6ICAgICAgICAgIHphYmJpeC1wcm94eQojIFJlcXVpcmVkLVN0YXJ0OiAgICAkcmVtb3RlX2ZzICRuZXR3b3JrIAojIFJlcXVpcmVkLVN0b3A6ICAgICAkcmVtb3RlX2ZzCiMgRGVmYXVsdC1TdGFydDogICAgIDIgMyA0IDUKIyBEZWZhdWx0LVN0b3A6ICAgICAgMCAxIDYKIyBTaG9ydC1EZXNjcmlwdGlvbjogU3RhcnQgemFiYml4LXByb3h5IGRhZW1vbgojIyMgRU5EIElOSVQgSU5GTwoKc2V0IC1lCgpOQU1FPXphYmJpeF9wcm94eQpEQUVNT049L3Vzci9zYmluLyROQU1FCkRFU0M9IlphYmJpeCBwcm94eSBkYWVtb24iCgp0ZXN0IC14ICREQUVNT04gfHwgZXhpdCAwCgpESVI9L3J1bi96YWJiaXgKUElEPSRESVIvJE5BTUUucGlkClJFVFJZPTE1CgppZiB0ZXN0ICEgLWQgIiRESVIiOyB0aGVuCiAgbWtkaXIgLXAgIiRESVIiCiAgY2hvd24gLVIgemFiYml4OnphYmJpeCAiJERJUiIKZmkKCmV4cG9ydCBQQVRIPSIke1BBVEg6KyRQQVRIOn0vdXNyL3NiaW46L3NiaW4iCgojIGRlZmluZSBMU0IgbG9nXyogZnVuY3Rpb25zLgouIC9saWIvbHNiL2luaXQtZnVuY3Rpb25zCgppZiBbIC1yICIvZXRjL2RlZmF1bHQvemFiYml4LXByb3h5IiBdOyB0aGVuCiAgICAuIC9ldGMvZGVmYXVsdC96YWJiaXgtcHJveHkKZmkKCmNhc2UgIiQxIiBpbgogIHN0YXJ0KQogICAgbG9nX2RhZW1vbl9tc2cgIlN0YXJ0aW5nICRERVNDIiAiJE5BTUUiCiAgICBzdGFydC1zdG9wLWRhZW1vbiAtLW9rbm9kbyAtLXN0YXJ0IC0tcGlkZmlsZSAkUElEIFwKICAgICAgLS1leGVjICREQUVNT04gPi9kZXYvbnVsbCAyPiYxCiAgICBjYXNlICIkPyIgaW4KICAgICAgICAwKSBsb2dfZW5kX21zZyAwIDs7CiAgICAgICAgKikgbG9nX2VuZF9tc2cgMTsgZXhpdCAxIDs7CiAgICBlc2FjCiAgICA7OwogIHN0b3ApCiAgICBsb2dfZGFlbW9uX21zZyAiU3RvcHBpbmcgJERFU0MiICIkTkFNRSIKICAgIHN0YXJ0LXN0b3AtZGFlbW9uIC0tb2tub2RvIC0tc3RvcCAtLXBpZGZpbGUgJFBJRCAtLXJldHJ5ICRSRVRSWQogICAgY2FzZSAiJD8iIGluCiAgICAgICAgMCkgbG9nX2VuZF9tc2cgMCA7OwogICAgICAgICopIGxvZ19lbmRfbXNnIDE7IGV4aXQgMSA7OwogICAgZXNhYwogICAgOzsKICBzdGF0dXMpCiAgICBzdGF0dXNfb2ZfcHJvYyAtcCAiJFBJRCIgIiREQUVNT04iICIkTkFNRSIgJiYgZXhpdCAwIHx8IGV4aXQgJD8KICAgIDs7CiAgcmVzdGFydHxmb3JjZS1yZWxvYWQpCiAgICAkMCBzdG9wCiAgICAkMCBzdGFydAogICAgOzsKICAqKQogICAgZWNobyAiVXNhZ2U6ICQwIHtzdGFydHxzdG9wfHJlc3RhcnR8Zm9yY2UtcmVsb2FkfSIgPiYyCiAgICBleGl0IDEKICAgIDs7CmVzYWMKCmV4aXQgMAo=" | base64 --decode > /etc/init.d/zabbix-proxy
chmod 755 /etc/init.d/zabbix-proxy



cd /lib/systemd/system
cat << 'EOF' > zabbix-proxy.service
[Unit]
Description=Zabbix Proxy
After=syslog.target
After=network.target

[Service]
Environment="CONFFILE=/etc/zabbix/zabbix_proxy.conf"
EnvironmentFile=-/etc/default/zabbix-proxy
Type=forking
Restart=on-failure
PIDFile=/run/zabbix/zabbix_proxy.pid
KillMode=control-group
ExecStart=/usr/sbin/zabbix_proxy -c $CONFFILE
ExecStop=/bin/kill -SIGTERM $MAINPID
RestartSec=10s
TimeoutSec=infinity

[Install]
WantedBy=multi-user.target

EOF

# or
# echo "W1VuaXRdCkRlc2NyaXB0aW9uPVphYmJpeCBQcm94eQpBZnRlcj1zeXNsb2cudGFyZ2V0CkFmdGVyPW5ldHdvcmsudGFyZ2V0CgpbU2VydmljZV0KRW52aXJvbm1lbnQ9IkNPTkZGSUxFPS9ldGMvemFiYml4L3phYmJpeF9wcm94eS5jb25mIgpFbnZpcm9ubWVudEZpbGU9LS9ldGMvZGVmYXVsdC96YWJiaXgtcHJveHkKVHlwZT1mb3JraW5nClJlc3RhcnQ9b24tZmFpbHVyZQpQSURGaWxlPS9ydW4vemFiYml4L3phYmJpeF9wcm94eS5waWQKS2lsbE1vZGU9Y29udHJvbC1ncm91cApFeGVjU3RhcnQ9L3Vzci9zYmluL3phYmJpeF9wcm94eSAtYyAkQ09ORkZJTEUKRXhlY1N0b3A9L2Jpbi9raWxsIC1TSUdURVJNICRNQUlOUElEClJlc3RhcnRTZWM9MTBzClRpbWVvdXRTZWM9aW5maW5pdHkKCltJbnN0YWxsXQpXYW50ZWRCeT1tdWx0aS11c2VyLnRhcmdldAo=" | base64 --decode > /lib/systemd/system/zabbix-proxy.service

# reload systemd cache
systemctl daemon-reload








