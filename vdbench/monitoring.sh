#!/bin/bash
#setup and configure Postgres and node monitoring for Prometheus
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