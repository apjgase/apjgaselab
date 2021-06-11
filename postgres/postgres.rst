.. title:: LAB: Postgres DB

.. _postgres:

----------------------------
LAB: Postgres DB
----------------------------

In this lab, you will provision Postgres DB server and will monitor performance utilization of DB and node with Grafana while running HammerDB test.

Postgres DB VM
+++++

#. Create a VM with 8 (minimum) or 12/16 (recommended) vCPUs and at least 32 Gb of memory. Use Centos-7-x86_64-GenericCloud image.

#. Attach additional drives:

    scsi 1,2,3,4 - 60Gb each (recommended); 30Gb each (minimum) for data
    scsi 5,6 - 20 Gb (recommended); 10Gb each (minimum) for logs

#. Add the following cloud-init script:

    .. literalinclude :: cloudinit.yaml
      :language: YAML

#. It will take 5-10 minutes to fully execute  cloud-init script and reboot the system.

#. After reboot, log in via ssh to configure LVM, install and configure Postgres:

    .. literalinclude :: Postgres-server.sh
      :language: bash

#. Install and configure data collectors for Postgres and node monitoring:

    .. literalinclude :: monitoring.sh
      :language: bash


Monitoring VM
+++++

#. It's recommended to run a monitoring VM on the separate cluster.

#. Deploy a VM (4VCPU/8Gb/Use Centos-7-x86_64-GenericCloud image) with generic cloud-init script.

    .. literalinclude :: ../cloudinit/generic.yaml
      :language: YAML

#. Install and configure Prometheus:

    .. literalinclude :: ../grafana/prometheus.sh
      :language: bash

#. Check if Prometheus is up and running by opening a http://monitoring_server_ip:9090

#. Add postgres and node collectors to the Prometheus configuration file /etc/prometheus/prometheus.yml (**replace POSTGRES_SERVER_IP with the ip address**):

    .. literalinclude :: ../grafana/postgres_node_exporter.yml
      :language: YAML

#. Restart PrometheusL: 

  - sudo systemctl restart prometheus
  - sudo systemctl status prometheus

#. Install and configure Grafana

    .. literalinclude :: ../grafana/grafana.sh
      :language: bash

#. Navigate to http://monitoringserver:3000 (admin:admin).

#. Click on "Add Data source" -> Prometheus.

#. Set URL to http://localhost:9090 and leave the rest default; click "Save and test"

#. Click "+" in the left-side column and click "Import". 

    .. literalinclude :: ../grafana/Postgres Overview-1561698919979.json
      :language: JSON
    
Hammer DB
+++++

#. Download Hammer-DB howto from OneDrive share.

#. Deploy a Windows VM

#. Download Postgres installer from https://www.postgresql.org/download/windows/, install client and PgAdmin web console.

#. Download and install Hammer-DB 64 bit (https://sourceforge.net/projects/hammerdb/files/HammerDB/HammerDB-3.1/HammerDB-3.1-Win-x86-64-Setup.exe/download)

#. Follow the steps in the document, with the few changes:

    - select Postgres instead of Oracle
    - Configure < 40 users