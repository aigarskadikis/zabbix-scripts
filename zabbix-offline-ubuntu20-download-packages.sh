# Download Zabbix repo
wget https://repo.zabbix.com/zabbix/5.4/ubuntu/pool/main/z/zabbix-release/zabbix-release_5.4-1+ubuntu20.04_all.deb

# Install Zabbix repo
sudo dpkg -i zabbix-release_5.4-1+ubuntu20.04_all.deb

# Update package list
sudo apt update

# Clear local apt cache
sudo rm -rf /var/cache/apt/archives/*

# Download all Zabbix packages with all dependencies
sudo apt-get install --download-only zabbix-server-mysql zabbix-frontend-php zabbix-apache-conf zabbix-sql-scripts zabbix-agent mysql-server

# Create folder for .deb
mkdir ./zabbix

# Copy all Zabbix .deb
sudo cp -r /var/cache/apt/archives/* ./zabbix/

# Copy this folder to your isolated server and install Zabbix from local .deb
sudo dpkg -i ./zabbix/*.deb
