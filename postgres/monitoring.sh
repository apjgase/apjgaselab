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

#setup and configure postgres exporter for Prometheus
#will listen on :9187
sudo wget https://github.com/wrouesnel/postgres_exporter/releases/download/v0.4.7/postgres_exporter_v0.4.7_linux-amd64.tar.gz
sudo tar -xvzf postgres_exporter_v0.4.7_linux-amd64.tar.gz
sudo cp postgres_exporter_v0.4.7_linux-amd64/postgres_exporter  /usr/local/bin/
sudo chown postgres:postgres /usr/local/bin/postgres_exporter

echo '[Unit]
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
WantedBy=multi-user.target' | sudo tee -a /etc/systemd/system/postgres_exporter.service

sudo systemctl daemon-reload
sudo systemctl enable postgres_exporter
sudo systemctl start postgres_exporter
