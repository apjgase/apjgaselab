terraform {
  required_providers {
    nutanix = {
      source = "nutanix/nutanix"
      version = "1.2.0"
    }
  }
}

#############################################################################
# Demo for VM provsioning from the image + subnet + category
#############################################################################

#define vlan_id

variable "vlan_id" {
  default = "635"
}

variable "username" {
  default  = "admin"
}

variable "password" {
  default  = "Nutanix@123"
}

variable "endpoint" {
  default  = "10.129.34.130"
}

variable "apache0_internal_ip" {
  default = "10.129.35.201"
}

variable "category_name" {
  default = "Country"
}

variable "category_value" {
  default = "MY"
}



#images ID
variable "apache0_template" {
  default = "8b38684b-75f8-4dc3-8534-2731c73fa52b"
}    


#cluster credentials
  provider "nutanix" {
  username  = "${var.username}"
  password  = "${var.password}"
  endpoint  = "${var.endpoint}"
  insecure  = true
  port      = 9440
}  

data "nutanix_clusters" "clusters" {}


locals {
  #cluster1 = "${data.nutanix_clusters.clusters.entities.1.metadata.uuid}"
  net_name = "VPC-${var.vlan_id}"
}

#test

### Subnet Resources (Virtual Networks within AHV)
# ### Define Terraform Managed Subnets
resource "nutanix_subnet" "VPC" {
  # What cluster will this VLAN live on?
  cluster_uuid = "${data.nutanix_clusters.clusters.entities.2.metadata.uuid}"
  #cluster_uuid = "0005c45f-18a5-f6df-499c-ac1f6b3b39dd"

  # General Information
  name        = "${local.net_name}"
  vlan_id     = "${var.vlan_id}"
  subnet_type = "VLAN"

  # Provision a Managed L3 Network
  # This bit is only needed if you intend to turn on AHV's IPAM
  
 subnet_ip = "10.129.35.0"
 default_gateway_ip = "10.129.35.1"
 prefix_length      = 24

  
}

### Category

resource "nutanix_category_key" "test-category"{
    name = "${var.category_name}"
    description = "Country Support Category Key"
}

resource "nutanix_category_value" "test"{
    name = nutanix_category_key.test-category.id
    description = "Country Category Value"
    value = "${var.category_value}"
}


### Virtual Machine Resources

resource "nutanix_virtual_machine" "apache0_vm" {
  # General Information
  name                 = "${local.net_name}-apache0"
  num_vcpus_per_socket = 2
  num_sockets          = 1
  memory_size_mib      = 8192

  # What cluster will this VM live on?
  cluster_uuid = data.nutanix_clusters.clusters.entities.2.metadata.uuid
  #cluster_uuid = "0005c45f-18a5-f6df-499c-ac1f6b3b39dd"

guest_customization_cloud_init_user_data = "ZGlzYWJsZV9yb290OiBGYWxzZQpzc2hfZW5hYmxlZDogVHJ1ZQpzc2hfcHdhdXRoOiBUcnVl"

categories {
    name   = nutanix_category_key.test-category.name
    value  = nutanix_category_value.test.value
    }

  # What networks will this be attached to?
  nic_list {
    subnet_uuid = "${nutanix_subnet.VPC.id}"

    ip_endpoint_list {
         ip   = "${var.apache0_internal_ip}"
         type = "ASSIGNED"
   }
  }
  

  # What disk/cdrom configuration will this have?
  disk_list {
    data_source_reference = {
      kind = "image"
      uuid="${var.apache0_template}"
    }

    device_properties {
      disk_address = {
        device_index = 0
        adapter_type = "SCSI"
      }
      device_type = "DISK"
    }
  }
}

