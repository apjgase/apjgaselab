.. title:: LAB: Terraform

.. _terraform:

----------------------------
LAB: Terraform
----------------------------

In this lab, we will use Terraform to create a VPC-like environment on Nutanix. 

Terraform’s representation of your resources in configuration files is referred to as Infrastructure as Code (IAC). The benefits of this methodology and of using Terraform include:

#. Version control of your infrastructure. Because your resources are declared in code, you can track changes to that code over time in version control systems like Git.

#. Minimization of human error. Terraform’s analysis of your configuration files will produce the same results every time it creates your declared resources. As well, telling Terraform to repeatedly apply the same configuration will not result in extra resource creation, as Terraform tracks the changes it makes over time.

#. Better collaboration among team members. Terraform’s backends allow multiple team members to safely work on the same Terraform configuration simultaneously.

Terraform’s configuration files can be written in either the HashiCorp Configuration Language (HCL), or in JSON. HCL is a configuration language authored by HashiCorp for use with its products, and it is designed to be human readable and machine friendly. It is recommended that you use HCL over JSON for your Terraform deployments.


Environment
+++++

Terraform will provision a private subnet, then will create a project and deploy 3-tier Wordpress app.

(routable subnet) - [HA Proxy] - (private subnet) - [Apache x 2] - [MySQL] - [NAT server] - (routable subnet)

TBD: proper network diagram


Pre-requisites
+++++
#. As of 16/07/19, this lab could be run only on SG Cluster 1. If you want to run it on any other cluster, please download images first.
#. Non-routable VLANs should be configured on TOR switches. There are VLANs 10-30 configured on SG Cluster 1.
#. Make sure that there is no subnet with specific VPC # exists on the cluster.
#. At the moment of publication, Nutanix provider for Terraform supported on vesion 0.11 only.

If you want to learn more about Terraform, please refer to the https://www.terraform.io.

Management VM
+++++

#. Create a VM with 2 vCPUs and at 8Gb of memory. Use **Centos-7-x86_64-GenericCloud** image and generic cloud-init script.

#. Download terraform 0.11.11 from this page https://releases.hashicorp.com/terraform/0.11.11/

#. Extract terraform binary and copy it to /usr/local/bin/

Terraform configuration
+++++

#. Nutanix provider for terraform enables you to provision subnets, VMs, categories and other Nutunix configuration items within Terraform code. Project creation is not supported in Nutanix provider for terraform, so we will use python script as an terraform external provider to provision a project.
#. Download `terraform configuration file <https://raw.githubusercontent.com/apjgase/apjgaselab/master/terraform/nutanix.tf>`_ and external provider `python script <https://raw.githubusercontent.com/apjgase/apjgaselab/master/terraform/create_project.py>`_ and upload it to the same folder on Management VM. 
#. Run chmod +x create_project.py.
#. Edit nutanix.tf and set VLAN, PC username/IP/password:

    .. code-block:: JSON

        variable "vlan_id" {
            default = "12"
        }

        variable "username" {
            default  = "admin"
        }

        variable "password" {
            default  = "PASSWORD"
        }

        variable "endpoint" {
            default  = "PC_IP"
        }

#. Run the init command from the project’s directory::
    
    terraform init

#. This command will download the Nutanix provider plugin and take other actions needed to initialize your project. It is safe to run this command more than once, but you generally will only need to run it again if you are adding another provider to your project.
#. Verify that Terraform will create the resources as you expect them to be created before making any actual changes to your infrastructure. To do this, you run the plan command::

    terraform plan

#. This command will generate a report detailing what actions Terraform will take to set up your Nutanix resources. If you are satisfied with this report, run apply::

    terraform apply

#. This command will ask you to confirm that you want to proceed. Once Terraform will apply your configuration, it will show the output report::

    nutanix_virtual_machine.mysql_vm: Still creating... (10s elapsed)
    nutanix_virtual_machine.nat_vm: Still creating... (10s elapsed)
    nutanix_virtual_machine.haproxy_vm: Still creating... (10s elapsed)
    nutanix_virtual_machine.apache0_vm: Still creating... (10s elapsed)
    nutanix_virtual_machine.apache1_vm: Still creating... (10s elapsed)
    nutanix_virtual_machine.mysql_vm: Creation complete after 18s (ID: 99228e2b-f762-4c35-939a-b220d45ccd67)
    nutanix_virtual_machine.apache1_vm: Creation complete after 18s (ID: bf45a0ab-3358-4779-9829-d51193fa082e)
    nutanix_virtual_machine.nat_vm: Still creating... (20s elapsed)
    nutanix_virtual_machine.haproxy_vm: Still creating... (20s elapsed)
    nutanix_virtual_machine.apache0_vm: Still creating... (20s elapsed)
    nutanix_virtual_machine.haproxy_vm: Creation complete after 24s (ID: 2fad68e2-2270-45e4-9daa-f450f61622ca)
    nutanix_virtual_machine.apache0_vm: Creation complete after 24s (ID: 07baceca-2e79-49d3-822f-9deb9eb88093)
    nutanix_virtual_machine.nat_vm: Creation complete after 24s (ID: fa7ca126-ef4b-4fdb-9efd-f32c91c29b22)

    Apply complete! Resources: 6 added, 0 changed, 0 destroyed.

    Outputs:

    haproxy ip = 10.139.80.64
    nat ip = 10.139.80.65

#. Open web browser and navigate to the ip address of the haproxy. It will take 2-3 minutes to start the app.
#. Review new project, subnet and VMs created in PC.

