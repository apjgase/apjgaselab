#step 0

#----
#!/bin/bash
set -ex
#set hostname
sudo hostnamectl set-hostname node1
#update all
sudo yum update -y -q
#install pcs
sudo yum install -y -q pcs pacemaker fence-agents-all psmisc policycoreutils-python
#install drdb
sudo rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
sudo rpm -Uvh http://www.elrepo.org/elrepo-release-7.0-2.el7.elrepo.noarch.rpm
sudo yum install -y -q kmod-drbd90 drbd90-utils
sudo yum install -y -q mariadb-server mariadb
#configure and start pcs
sudo systemctl start pcsd
sudo systemctl enable pcsd
echo "nutanix" | sudo passwd hacluster --stdin
#format disk
echo -e "o\nn\np\n1\n\n\nw" | sudo fdisk /dev/sdb
#update etc hosts
echo '@@{address}@@ node1 ' | sudo tee -a /etc/hosts
echo '@@{node2vm.address}@@ node2 ' | sudo tee -a /etc/hosts
sudo systemctl disable mariadb.service
#configure mysql
echo "[mysqld]"| sudo tee /etc/my.cnf
echo "symbolic-links=0"| sudo tee -a /etc/my.cnf
echo "bind-address            = 0.0.0.0"| sudo tee -a /etc/my.cnf
echo "datadir                 = /var/lib/mysql"| sudo tee -a /etc/my.cnf
echo "pid_file                = /var/run/mariadb/mysqld.pid"| sudo tee -a /etc/my.cnf
echo "socket                  = /var/run/mariadb/mysqld.sock"| sudo tee -a /etc/my.cnf
echo "[mysqld_safe]"| sudo tee -a /etc/my.cnf
echo "bind-address            = 0.0.0.0"| sudo tee -a /etc/my.cnf
echo "datadir                 = /var/lib/mysql"| sudo tee -a /etc/my.cnf
echo "pid_file                = /var/run/mariadb/mysqld.pid"| sudo tee -a /etc/my.cnf
echo "socket                  = /var/run/mariadb/mysqld.sock"| sudo tee -a /etc/my.cnf
echo "!includedir /etc/my.cnf.d"| sudo tee -a /etc/my.cnf
#configure drdb
echo "resource mysql01 {"| sudo tee -a /etc/drbd.d/mysql01.res
echo " protocol C;"| sudo tee -a /etc/drbd.d/mysql01.res
echo " meta-disk internal;"| sudo tee -a /etc/drbd.d/mysql01.res
echo " device /dev/drbd0;"| sudo tee -a /etc/drbd.d/mysql01.res
echo " disk   /dev/sdb1;"| sudo tee -a /etc/drbd.d/mysql01.res
echo " handlers {"| sudo tee -a /etc/drbd.d/mysql01.res
echo '  split-brain "/usr/lib/drbd/notify-split-brain.sh root";'| sudo tee -a /etc/drbd.d/mysql01.res
echo " }"| sudo tee -a /etc/drbd.d/mysql01.res
echo " net {"| sudo tee -a /etc/drbd.d/mysql01.res
echo "  allow-two-primaries no;"| sudo tee -a /etc/drbd.d/mysql01.res
echo "  after-sb-0pri discard-zero-changes;"| sudo tee -a /etc/drbd.d/mysql01.res
echo "  after-sb-1pri discard-secondary;"| sudo tee -a /etc/drbd.d/mysql01.res
echo "  after-sb-2pri disconnect;"| sudo tee -a /etc/drbd.d/mysql01.res
echo "  rr-conflict disconnect;"| sudo tee -a /etc/drbd.d/mysql01.res
echo " }"| sudo tee -a /etc/drbd.d/mysql01.res
echo " disk {"| sudo tee -a /etc/drbd.d/mysql01.res
echo "  on-io-error detach;"| sudo tee -a /etc/drbd.d/mysql01.res
echo " }"| sudo tee -a /etc/drbd.d/mysql01.res
echo " syncer {"| sudo tee -a /etc/drbd.d/mysql01.res
echo "  verify-alg sha1;"| sudo tee -a /etc/drbd.d/mysql01.res
echo " }"| sudo tee -a /etc/drbd.d/mysql01.res
echo " on node1 {"| sudo tee -a /etc/drbd.d/mysql01.res
echo "  address  @@{address}@@:7789;"| sudo tee -a /etc/drbd.d/mysql01.res
echo " }"| sudo tee -a /etc/drbd.d/mysql01.res
echo " on node2 {"| sudo tee -a /etc/drbd.d/mysql01.res
echo "  address  @@{node2vm.address}@@:7789;"| sudo tee -a /etc/drbd.d/mysql01.res
echo " }"| sudo tee -a /etc/drbd.d/mysql01.res
echo "}"| sudo tee -a /etc/drbd.d/mysql01.res

####
REBOOT VIA API

#step 1, node 1 only

#!/bin/bash
set -ex
#configure pcs
sudo pcs cluster auth node1 node2 -u hacluster -p nutanix --force
sudo pcs cluster setup --force --name calmcluster node1 node2
sudo pcs cluster start --all
#configure DRBD
sudo drbdadm create-md mysql01
sudo drbdadm up mysql01
sudo drbdadm primary --force mysql01
sudo mkfs.ext4 -m 0 -L drbd /dev/drbd0
sudo tune2fs -c 30 -i 180d /dev/drbd0
sudo mount /dev/drbd0 /mnt
sudo systemctl start mariadb
sudo mysql_install_db --datadir=/mnt --user=mysql
sudo umount /mnt
sudo systemctl stop mariadb
#start cluster
sudo pcs cluster cib clust_cfg
sudo pcs -f clust_cfg property set stonith-enabled=false
sudo pcs -f clust_cfg property set no-quorum-policy=ignore
sudo pcs -f clust_cfg resource defaults resource-stickiness=200
sudo pcs -f clust_cfg resource create mysql_data01 ocf:linbit:drbd drbd_resource=mysql01 op monitor interval=30s
sudo pcs -f clust_cfg resource master MySQLClone01 mysql_data01 master-max=1 master-node-max=1 clone-max=2 clone-node-max=1 notify=true
sudo pcs -f clust_cfg resource create mysql_fs01 Filesystem device="/dev/drbd0" directory="/var/lib/mysql" fstype="ext4"
sudo pcs -f clust_cfg constraint colocation add mysql_fs01 with MySQLClone01 INFINITY with-rsc-role=Master
sudo pcs -f clust_cfg constraint order promote MySQLClone01 then start mysql_fs01
sudo pcs -f clust_cfg resource create mysql_service01 ocf:heartbeat:mysql binary="/usr/bin/mysqld_safe" config="/etc/my.cnf" datadir="/var/lib/mysql" pid="/var/lib/mysql/mysql.pid" socket="/var/lib/mysql/mysql.sock" additional_parameters="--bind-address=0.0.0.0" op start timeout=60s op stop timeout=60s op monitor interval=20s timeout=30s
sudo pcs -f clust_cfg constraint colocation add mysql_service01 with mysql_fs01 INFINITY
sudo pcs -f clust_cfg constraint order mysql_fs01 then mysql_service01

sudo pcs -f clust_cfg resource create mysql_VIP01 ocf:heartbeat:IPaddr2 ip=10.139.80.150 cidr_netmask=22 nic=eth0:1 op monitor interval=30s
sudo pcs -f clust_cfg constraint colocation add mysql_VIP01 with mysql_service01 INFINITY
sudo pcs -f clust_cfg constraint order mysql_service01 then mysql_VIP01
sudo pcs -f clust_cfg constraint
sudo pcs -f clust_cfg resource show
sudo pcs --force cluster cib-push clust_cfg
sudo pcs status

