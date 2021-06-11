#Postgres DB server setup
#Centos-7-x86_64-GenericCloud image
#disks layout
#scsi0 - centos image
#scsi1/2/3/4 - Data drives / 60Gb each
#scsi5/6 - Log drives / 20Gb each
#!/bin/bash

sudo yum -y upgrade
sudo curl -O http://dl.fedoraproject.org/pub/epel/7/x86_64/e/epel-release-7-10.noarch.rpm
sudo rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
sudo rpm -Uvh http://www.elrepo.org/elrepo-release-7.0-3.el7.elrepo.noarch.rpm
sudo rpm -ihv epel-release-7-10.noarch.rpm 
 
sudo yum update -y
sudo yum -y install htop wget iotop xfs* bc unzip lvm2*

echo "System packages are installed"
 
#---------
#Configure disks/LVM
#---------

##############
#
# LVM setup script for PostgreSQL . 4 disks for DATA and 2 for logs
# Data disks are 60GB | Log disks are 20GB 
#
#############
 
 
#PGSQL data
sudo pvcreate /dev/sdb /dev/sdc /dev/sdd /dev/sde
sudo vgcreate pgDataVG /dev/sdb /dev/sdd /dev/sdc /dev/sde
sudo lvcreate -l 100%FREE -i4 -I1M -n pgDataLV pgDataVG          ## Use 1MB to avoid IO amplification
#lvcreate -l 100%FREE -i4 -I4M -n pgDataLV pgDataVG
 
 
#PGSQL logs
sudo pvcreate /dev/sdf /dev/sdg 
sudo vgcreate pgLogVG /dev/sdf /dev/sdg
sudo lvcreate -l 100%FREE -i2 -I1M -n pgLogLV pgLogVG            ## Use 1MB to avoid IO amplification
#lvcreate -l 100%FREE -i2 -I4M -n pgLogLV pgLogVG
 
 
#Disable LVM read ahead
sudo lvchange -r 0 /dev/pgDataVG/pgDataLV
sudo lvchange -r 0 /dev/pgLogVG/pgLogLV
 
 
#Format LVMs with ext4 and use nodiscard to make sure format time is fast on Nutanix due to SCSI unmap
sudo mkfs.ext4 -E nodiscard /dev/pgDataVG/pgDataLV
sudo mkfs.ext4 -E nodiscard /dev/pgLogVG/pgLogLV
 
echo "LVM configured"
#---------
#Postgres setup
#---------

 
sudo wget -c https://download.postgresql.org/pub/repos/yum/9.6/redhat/rhel-7-x86_64/pgdg-centos96-9.6-3.noarch.rpm
sudo yum -y install pgdg-centos96-9.6-3.noarch.rpm
sudo rpm --import http://packages.2ndquadrant.com/repmgr/RPM-GPG-KEY-repmgr
sudo yum install -y http://packages.2ndquadrant.com/repmgr/yum-repo-rpms/repmgr-rhel-1.0-1.noarch.rpm
 
# Install PostgreSQL
sudo yum -y install postgresql96 postgresql96-contrib postgresql96-server postgresql96-devel postgresql96-plpython
 
echo "Postgres installed"
#------- 
#Postgres config:
#------
 

#run initdb
sudo /usr/pgsql-9.6/bin/postgresql96-setup initdb
 
#start and stop postgresql to make sure DB creates the required directories
sudo systemctl start postgresql-9.6.service
sudo systemctl stop postgresql-9.6.service
 
##copy the created postgres directory to a temp directory
 
sudo mkdir /tmp/pgsql
 
sudo mv /var/lib/pgsql/9.6/data /tmp/pgsql
 
#Create directory , fix permissions and Mount LVM
sudo mkdir /var/lib/pgsql/9.6/data/
sudo mount -o noatime,barrier=0 /dev/pgDataVG/pgDataLV /var/lib/pgsql/9.6/data/
 
sudo mkdir /var/lib/pgsql/9.6/data/pg_xlog
sudo mount -o noatime,barrier=0 /dev/pgLogVG/pgLogLV /var/lib/pgsql/9.6/data/pg_xlog
 
sudo chown -R postgres:postgres /var/lib/pgsql/9.6/data/
 
#move the xlog to the new LVM
sudo find /tmp/pgsql/data/pg_xlog -maxdepth 1 -mindepth 1 -exec mv -t /var/lib/pgsql/9.6/data/pg_xlog/ {} +
 
#remove pg_xlog from temp dir to avoid being copied again
sudo rm -rf /tmp/pgsql/data/pg_xlog
 
#move the pgsql directory to the LVM
sudo find /tmp/pgsql/data -maxdepth 1 -mindepth 1 -exec mv -t /var/lib/pgsql/9.6/data/ {} +
 
sudo chmod -R 0700 /var/lib/pgsql/9.6/data
 
#enable service on boot
sudo systemctl enable postgresql-9.6.service
 
#add mount points to /etc/fstab
echo "/dev/mapper/pgDataVG-pgDataLV /var/lib/pgsql/9.6/data ext4 rw,seclabel,noatime,nobarrier,stripe=4096,data=ordered 0 0" | sudo tee -a /etc/fstab
echo "/dev/mapper/pgLogVG-pgLogLV /var/lib/pgsql/9.6/data/pg_xlog ext4 rw,seclabel,noatime,nobarrier,stripe=2048,data=ordered 0 0" | sudo tee -a  /etc/fstab

#allow external connections
echo "listen_addresses = '*'" | sudo tee -a /var/lib/pgsql/9.6/data/postgresql.conf
echo "host    all             all              0.0.0.0/0                       password" | sudo tee -a pg_hba.conf
echo "host    all             all              ::/0                            password" | sudo tee -a pg_hba.conf

echo "Postgres configured"
 
sudo systemctl status postgresql-9.6
sudo systemctl restart postgresql-9.6
sudo systemctl status postgresql-9.6

sudo -u postgres psql -U postgres -d postgres -c "alter user postgres with password 'Nutanix@123';"
 
echo "Postgres password changed"

#setup and configure node monitoring for Prometheus
#will listen on :9100

sudo wget https://github.com/prometheus/node_exporter/releases/download/v0.17.0/node_exporter-0.17.0.linux-amd64.tar.gz
sudo tar -xvzf node_exporter-0.17.0.linux-amd64.tar.gz
sudo useradd -rs /bin/false nodeusr
sudo mv node_exporter-0.17.0.linux-amd64/node_exporter /usr/local/bin/

echo "[Unit]
Description=Node Exporter
After=network.target

[Service]
User=nodeusr
Group=nodeusr
Type=simple
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=multi-user.target" | sudo tee -a /etc/systemd/system/node_exporter.service

sudo systemctl daemon-reload
sudo systemctl enable node_exporter
sudo systemctl start node_exporter

#setup and configure postgres exporter for Prometheus
#will listen on :9187
sudo wget https://github.com/wrouesnel/postgres_exporter/releases/download/v0.4.7/postgres_exporter_v0.4.7_linux-amd64.tar.gz
sudo tar -xvzf postgres_exporter_v0.4.7_linux-amd64.tar.gz
sudo cp postgres_exporter_v0.4.7_linux-amd64/postgres_exporter  /usr/local/bin/
sudo chown postgres:postgres /usr/local/bin/postgres_exporter

echo "[Unit]
Description=Prometheus PostgreSQL Exporter
After=network.target

[Service]
User=postgres
Group=postgres
Type=simple
Environment="DATA_SOURCE_NAME=user=postgres host=/var/run/postgresql/ sslmode=disable"
ExecStart=/usr/local/bin/postgres_exporter --web.listen-address=:9187
Restart=always

[Install]
WantedBy=multi-user.target" | sudo tee -a /etc/systemd/system/postgres_exporter.service

sudo systemctl daemon-reload
sudo systemctl enable postgres_exporter
sudo systemctl start postgres_exporter

