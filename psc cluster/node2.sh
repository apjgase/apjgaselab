#step 0

#----
#!/bin/bash
set -ex
sudo hostnamectl set-hostname node2
#update all
sudo yum update -y -q
#install pcs
sudo yum install -y -q pcs pacemaker fence-agents-all psmisc policycoreutils-python
#install drdb
sudo rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
sudo rpm -Uvh http://www.elrepo.org/elrepo-release-7.0-2.el7.elrepo.noarch.rpm
sudo yum install -y -q kmod-drbd90 drbd90-utils
sudo yum install -y -q mariadb-server mariadb
sudo systemctl start pcsd
sudo systemctl enable pcsd
echo "nutanix" | sudo passwd hacluster --stdin
echo -e "o\nn\np\n1\n\n\nw" | sudo fdisk /dev/sdb
echo '@@{node1vm.address}@@ node1 ' | sudo tee -a /etc/hosts
echo '@@{address}@@ node2 ' | sudo tee -a /etc/hosts
sudo systemctl disable mariadb.service
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
echo "  address  @@{node1vm.address}@@:7789;"| sudo tee -a /etc/drbd.d/mysql01.res
echo " }"| sudo tee -a /etc/drbd.d/mysql01.res
echo " on node2 {"| sudo tee -a /etc/drbd.d/mysql01.res
echo "  address  @@{address}@@:7789;"| sudo tee -a /etc/drbd.d/mysql01.res
echo " }"| sudo tee -a /etc/drbd.d/mysql01.res
echo "}"| sudo tee -a /etc/drbd.d/mysql01.res
#---

reboot


#step 2
#!/bin/bash
set -ex
sudo drbdadm create-md mysql01
sudo drbdadm up mysql01


