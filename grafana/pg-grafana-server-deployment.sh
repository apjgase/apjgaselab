#!/bin/bash
#install prometheus on Grafana server
#uncomment lines below if cloud-init was not used
yum install gcc-c++
yum install make
yum install unzip
yum install bash-completion
yum install python-pip
yum install ntp
yum install ntpdate
yum install python36
yum install python36-setuptools
yum install htop 
yum install wget 
yum install iotop 
systemctl stop firewalld
systemctl disable firewalld
/sbin/setenforce 0
sed -i -e 's/permissive/disabled/g' /etc/selinux/config
sed -i -e 's/enabled/disabled/g' /etc/selinux/config
/bin/python3.6 -m ensurepip
pip install -U pip
ntpdate -u -s 0.pool.ntp.org 1.pool.ntp.org 2.pool.ntp.org 3.pool.ntp.org
systemctl restart ntpd

#Prometheus and grafana deployment. Edit /etc/prometheus/prometheus.yaml after installation and set correct clients 

sudo wget https://github.com/prometheus/prometheus/releases/download/v2.8.1/prometheus-2.8.1.linux-amd64.tar.gz
sudo useradd --no-create-home --shell /bin/false prometheus
sudo mkdir /etc/prometheus
sudo mkdir /var/lib/prometheus
sudo chown prometheus:prometheus /etc/prometheus
sudo chown prometheus:prometheus /var/lib/prometheus
sudo tar -xvzf prometheus-2.8.1.linux-amd64.tar.gz
sudo mv prometheus-2.8.1.linux-amd64 prometheuspackage
sudo cp prometheuspackage/prometheus /usr/local/bin/
sudo cp prometheuspackage/promtool /usr/local/bin/
sudo chown prometheus:prometheus /usr/local/bin/prometheus
sudo chown prometheus:prometheus /usr/local/bin/promtool
sudo cp -r prometheuspackage/consoles /etc/prometheus
sudo cp -r prometheuspackage/console_libraries /etc/prometheus
sudo chown -R prometheus:prometheus /etc/prometheus/consoles
sudo chown -R prometheus:prometheus /etc/prometheus/console_libraries

echo "global:
  scrape_interval: 5s

scrape_configs:
  - job_name: 'prometheus_master'
    scrape_interval: 5s
    static_configs:
      - targets: ['localhost:9090']
  - job_name: 'vdbench1'
    scrape_interval: 5s
    static_configs:
      - targets: ['10.40.235.233:9100'] 
  - job_name: 'vdbench2'
    scrape_interval: 5s
    static_configs:
      - targets: ['10.40.232.2:9100']
  - job_name: 'vdbench3'
    scrape_interval: 5s
    static_configs:
      - targets: ['10.40.232.141:9100']
  - job_name: 'vdbench4'
    scrape_interval: 5s
    static_configs:
      - targets: ['10.40.239.43:9100']
  - job_name: 'vdbench5'
    scrape_interval: 5s
    static_configs:
      - targets: ['10.40.234.243:9100']" | sudo tee -a /etc/prometheus/prometheus.yml
      
sudo chown prometheus:prometheus /etc/prometheus/prometheus.yml

/etc/systemd/system/prometheus.service

echo "[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/prometheus \
--config.file /etc/prometheus/prometheus.yml \
--storage.tsdb.path /var/lib/prometheus/ \
--web.console.templates=/etc/prometheus/consoles \
--web.console.libraries=/etc/prometheus/console_libraries

[Install]
WantedBy=multi-user.target" | sudo tee -a /etc/systemd/system/prometheus.service
sudo systemctl daemon-reload
sudo systemctl enable prometheus
sudo systemctl start prometheus

#install grafana 

echo '[grafana]
name=grafana
baseurl=https://packages.grafana.com/oss/rpm
repo_gpgcheck=1
enabled=1
gpgcheck=1
gpgkey=https://packages.grafana.com/gpg.key
sslverify=1
sslcacert=/etc/pki/tls/certs/ca-bundle.crt' | sudo tee -a /etc/yum.repos.d/grafana.repo


sudo yum -y install grafana
sudo systemctl daemon-reload
sudo systemctl start grafana-server
sudo systemctl enable grafana-server

#grafana server should be accessible on :3000