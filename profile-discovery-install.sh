#create few profiles
mkdir -p /opt/{profile1,profile23,profile5}

#create some log files
touch /opt/{profile1,profile23,profile5}/SystemOut.log

#move to agent custom conf direcotry
cd /etc/zabbix/zabbix_agentd.d

#list profile.discovery UserParameter
echo "VXNlclBhcmFtZXRlcj1kaXNjb3Zlci5wcm9maWxlcyxscyAtMSAtZCAvb3B0LyogfCBzZWQgInMvXi97XCJ7I1BST0ZJTEV9XCI6XCIvO3MvJC9cIn0sLyIgfCB0ciAtY2QgIls6cHJpbnQ6XSIgfCBzZWQgInMvXi97XCJkYXRhXCI6Wy87cy8sJC9dfS8iCg==" | base64 --decode

#install parameter:
echo "VXNlclBhcmFtZXRlcj1kaXNjb3Zlci5wcm9maWxlcyxscyAtMSAtZCAvb3B0LyogfCBzZWQgInMvXi97XCJ7I1BST0ZJTEV9XCI6XCIvO3MvJC9cIn0sLyIgfCB0ciAtY2QgIls6cHJpbnQ6XSIgfCBzZWQgInMvXi97XCJkYXRhXCI6Wy87cy8sJC9dfS8iCg==" | base64 --decode > profile_discovery.conf

#check if it has installed
cat profile_discovery.conf

grep "^Include" /etc/zabbix/zabbix_agentd.conf


