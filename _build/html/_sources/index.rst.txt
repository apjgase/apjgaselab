.. title:: Labs for APJ Global Accounts SE

.. toctree::
  :maxdepth: 2
  :caption: Labs
  :name: _labs
  :hidden:

  postgres/postgres
  vdbench/vdbench
  terraform/terraform
  oracle/oracle

-------------
APJ Global Accounts SE Labs
-------------

Welcome to APJ GA SE labs collection!
Please refer to the OneDrive/Sharepoint/Teams share for the lab access details. This collection is internal-only, so please do not share the content with any 3rd party.

Note: Generally, labs are not configured to be secure. Please do not use any lab guide as-is to setup production environment.


Validated labs
-------------

- :ref:`postgres`
- :ref:`vdbench`
- :ref:`terraform`
- :ref:`oracle`

WIP Labs
------------

- :ref:`calm1`

.. _cloudinit:

Contributions
------------

Please help to make this collection better! If you have a lab to share, please reach out to maksim.malygin@nutanix.com.

Default Cloud-Init Script
----------------------------
Use this cloud-init script if there is no VM-specific file mentioned in a lab.

Notes:
1. Firewall and SELinux disabled by default.

    .. literalinclude :: cloudinit/generic.yaml
      :language: YAML