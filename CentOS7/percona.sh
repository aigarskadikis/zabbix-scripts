



# install percona MySQL repo
rpm -ivh https://www.percona.com/redir/downloads/percona-release/redhat/0.1-6/percona-release-0.1-6.noarch.rpm

# list available packages
yum list | grep percona

# install percona database server
yum -y install Percona-Server-server-57

