yum install ntp ntpdate
cp /usr/share/zoneinfo/Africa/Dar_es_Salaam /etc/localtime
date
# configure local ntp servers. communication happens through UDP 123
vim /etc/ntp.conf

# to synchronize the date the daemon must be stopped
systemctl stop ntpd

# execute instant sync ignoring that some application may crash
ntpdate -s lv.pool.ntp.org
systemctl start ntpd
systemctl enable ntpd
