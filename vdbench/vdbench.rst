.. title:: LAB: VDBench

.. _vdbench:

----------------------------
LAB: VDBench
----------------------------

In this lab, you will deploy VDBench VM(s) and run a storage perormance test.

VDBench VM(s)
+++++

#. Create a VM with 4 vCPUs and at 16Gb of memory. Use Centos-7-x86_64-GenericCloud image (from https://cloud.centos.org/centos/7/images/) and generic cloud-init script.

    .. literalinclude :: ../cloudinit/generic.yaml
      :language: YAML

#. Attach additional drive(s), at least 100Gb.

#. Install and configure data collector for node monitoring:

    .. literalinclude :: monitoring.sh
      :language: bash


#. Download vdbench50407.zip from OneDrive to your workstation and upload it to the VDBench machine with scp.

#. Clone the VM if you need to.

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

#. Add node collector(s) to the Prometheus configuration file /etc/prometheus/prometheus.yml (**replace POSTGRES_SERVER_IP with the ip address**):

    .. literalinclude :: ../grafana/node_exporter.yml
      :language: YAML

#. Restart Prometheus:: 
    
    sudo systemctl restart prometheus
    sudo systemctl status prometheus

#. Install and configure Grafana

    .. literalinclude :: ../grafana/grafana.sh
      :language: bash

#. Navigate to http://monitoringserver:3000 (admin:admin).

#. Click on "Add Data source" -> Prometheus.

#. Set URL to http://localhost:9090 and leave the rest default; click "Save and test"

#. Click "+" in the left-side column and click "Import". You can use the one of the JSON files provided below (clean and simple) or use Dashboard ID 1860 (comprehencive but complicated)

    Download `per-node dashboard <https://github.com/apjgase/apjgaselab/raw/master/grafana/Node%20Exporter%20Full-1562055551815.json>`_

    Download `combined view dashboard <https://github.com/apjgase/apjgaselab/raw/master/grafana/vdbench-combined-view.json>`_. You will need to edit each graph and change "sdh" in a query to the correct device name (i.e. "sdb" if you got only 2 disks connected to VMs)

   

Running VDBench
+++++

#. Log in to the VDBench VM and extract VDBench from the archive

#. You can use the following sample configuration file (save it as 1.test in the VDbench directory) or create your own using samples shipped with the VDBench::

    sd=sd1,lun=/dev/sdc,threads=32
    wd=wd1,sd=*,xfersize=(512,4,1k,1,1.5k,1,2k,1,2.5k,1,3k,1,3.5k,1,4k,67,8k,10,16k,7,32k,3,64k,3),seekpct=100,rdpct=75,openflags=o_direct
    rd=run1,wd=wd1,iorate=max,elapsed=504h,interval=1

#. Run VDBench as root and review the perormance data in Grafana::

    ./vdbench -f ./1.test   -o output_block_$(hostname)_$(date +'%Y-%m-%d_%k:%M')







