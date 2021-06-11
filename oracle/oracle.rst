.. title:: LAB: Oracle DB

.. _Oracle:

----------------------------
LAB: Oracle DB
----------------------------

Quick and simple lab to test Oracle DB on Nutanix

Oracle DB VM
+++++

#. Download images from https://drive.google.com/open?id=1HqaLhPQ1O5IGpMQAxuPvihFIPetLMLKu and deploy Oracle DB VM

SwingBench DB
+++++

#. Deploy a Windows VM

#. Install Java 8 and set environment variable "_JAVA_OPTIONS: -Xmx512M"

    .. image:: jaca.png

#. Download a SwingBench (http://www.dominicgiles.com/downloads.html)

#. Run /winbin/oewizard2.bat 

#. Use v2 and Create schema for the swingbench test. This may take few hours, so feel free to go for lunch!

#. Run /winbin/swingbench.bat and select default test

#. Set desirable number of users and start the test.