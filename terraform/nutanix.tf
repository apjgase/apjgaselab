#############################################################################
# Example .tf for Nutanix + Terraform
#############################################################################

#define vlan_id

variable "vlan_id" {
  default = "12"
}

variable "username" {
  default  = "admin"
}

variable "password" {
<<<<<<< HEAD
  default  = "PASSWORD"
}

variable "endpoint" {
  default  = "10.139.xx.xx"
=======
  default  = "Nutanix@123"
}

variable "endpoint" {
  default  = "10.139.80.175"
>>>>>>> master
}

#ip addresses, do not change
variable "haproxy_internal_ip" {
  default = "10.1.1.179"
}

variable "apache0_internal_ip" {
  default = "10.1.1.62"
}

variable "apache1_internal_ip" {
  default = "10.1.1.216"
}

variable "mysql_internal_ip" {
  default = "10.1.1.150"
}

variable "nat_internal_ip" {
  default ="10.1.1.1"
}


#images ID
variable "apache0_template" {
  default = "2a541c3b-2f24-4fc7-9f86-b483db302c93"
}    

variable "apache1_template" {
  default = "63471c33-3628-4989-a90a-0f336c82396b"
}

variable "haproxy_template" {
  default = "df680ed6-fea8-4aec-8edc-d9167716cc36"
}

variable "mysql_template" {
  default = "8dd81312-ec90-4186-9590-d918001e8157"
}

variable "nat_template" {
  default = "7d244413-7649-4080-a704-1bc30c59e1ac"
}

variable "external_net_uuid" {
  default = "c3ec0b2b-c33a-4a97-89d6-76c5f1583439"
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
  cluster1 = "${data.nutanix_clusters.clusters.entities.1.metadata.uuid}"
  net_name = "VPC-${var.vlan_id}"
  project_name = "VPC-${var.vlan_id}-project"
}

##########################
### Data Sources
##########################
### These are "lookups" to simply define an already existing object as a
### plain text name
### This is useful when managing a nutanix prism central instance from multiple
### state files, or deploying terraform into an existing / brownfield environment
### Virtual Machine Data Sources
# data "nutanix_virtual_machine" "nutanix_virtual_machine" {
#   vm_id = "${nutanix_virtual_machine.vm1.id}"
# }
### Image Data Sources
# data "nutanix_image" "test" {
#     metadata = {
#         kind = "image"
#     }
#     image_id = "${nutanix_image.test.id}"
# }
### Subnet Data Sources
# data "nutanix_subnet" "next-iac-managed" {
#     metadata = {
#         kind = "subnet"
#     }
#    image_id = "${nutanix_subnet.next-iac-managed.id}"
#}
### Cluster Data Sources
#data "nutanix_image" "test" {
#    metadata = {
#        kind = "image"
#    }
#    image_id = "${nutanix_image.test.id}"
#}
##########################
### Resources
##########################

### Subnet Resources (Virtual Networks within AHV)
# ### Define Terraform Managed Subnets
resource "nutanix_subnet" "VPC" {
  # What cluster will this VLAN live on?
  cluster_uuid = "${local.cluster1}"

  # General Information
  name        = "${local.net_name}"
  vlan_id     = "${var.vlan_id}"
  subnet_type = "VLAN"

  # Provision a Managed L3 Network
  # This bit is only needed if you intend to turn on AHV's IPAM
  
 subnet_ip = "10.1.1.0"

 #default_gateway_ip = ""
 prefix_length      = 24

  #dhcp_options {
  #  boot_file_name   = "bootfile"
  #  domain_name      = "tfntnxlab"
  #  tftp_server_name = "172.21.32.200"
  #}

  #dhcp_server_address {
 #   ip = "172.21.32.254"
 # }

 # dhcp_domain_name_server_list = ["172.21.30.223"]
 # dhcp_domain_search_list      = ["tfntnxlab.local"]
  #ip_config_pool_list_ranges   = ["172.21.32.3 172.21.32.253"] 
}

### Category Resource
/*
resource "nutanix_category_key" "test-category-key"{
    name        = "AppTier"
}


resource "nutanix_category_value" "test"{
    name        = "${nutanix_category_key.test-category-key.id}"
    value       = "WebTier"
}
*/
### Create a project using external provider

data "external" "project_uuid" {
  program = ["python", "${path.module}/create_project.py"]

  query = {
    ip_address = "${var.endpoint}",
    username = "${var.username}",
    password = "${var.password}",
    project_name = "${local.project_name}",
    network1_uuid = "${var.external_net_uuid}",
    network2_uuid = "${nutanix_subnet.VPC.id}"
    }
}

### Virtual Machine Resources

resource "nutanix_virtual_machine" "haproxy_vm" {
  # General Information
  name                 = "${local.net_name}-haproxy"
  num_vcpus_per_socket = 2
  num_sockets          = 1
  memory_size_mib      = 8192

<<<<<<< HEAD
  # Which cluster will this VLAN live on?
=======
  # What cluster will this VLAN live on?
>>>>>>> master
  cluster_uuid = "${local.cluster1}"

guest_customization_cloud_init_user_data = "ZGlzYWJsZV9yb290OiBGYWxzZQpzc2hfZW5hYmxlZDogVHJ1ZQpzc2hfcHdhdXRoOiBUcnVl"

categories = [{
    "AppTier" = "LBTier"
  }]

project_reference {
    kind = "project",
    uuid = "${data.external.project_uuid.result["uuid"]}"
    
    }
  # What networks will this be attached to?
  nic_list = [{
    # subnet_reference is saying, which VLAN/network do you want to attach here?
    subnet_uuid = "${var.external_net_uuid}"
  },
  {
    subnet_uuid = "${nutanix_subnet.VPC.id}"

    ip_endpoint_list = {
         ip   = "${var.haproxy_internal_ip}"
         type = "ASSIGNED"
   }
  }
  ]

  # What disk/cdrom configuration will this have?
  disk_list = [{
    data_source_reference = [{
      kind = "image"
      uuid="${var.haproxy_template}"
    }]

    device_properties = [{
      disk_address {
        device_index = 0
        adapter_type = "SCSI"
      }

      device_type = "DISK"
    }]
  }
  ]
}

resource "nutanix_virtual_machine" "nat_vm" {
  # General Information
  name                 = "${local.net_name}-nat"
  num_vcpus_per_socket = 2
  num_sockets          = 1
  memory_size_mib      = 8192

  # What cluster will this VLAN live on?
  cluster_uuid = "${local.cluster1}"

guest_customization_cloud_init_user_data = "ZGlzYWJsZV9yb290OiBGYWxzZQpzc2hfZW5hYmxlZDogVHJ1ZQpzc2hfcHdhdXRoOiBUcnVl"

categories = [{
    "AppTier" = "NATTier"
  }]

project_reference {
    kind = "project",
    uuid = "${data.external.project_uuid.result["uuid"]}"
}
  # What networks will this be attached to?
  nic_list = [{
    # subnet_reference is saying, which VLAN/network do you want to attach here?
    subnet_uuid = "${var.external_net_uuid}"
  },
  {
    subnet_uuid = "${nutanix_subnet.VPC.id}"

    ip_endpoint_list = {
         ip   = "${var.nat_internal_ip}"
         type = "ASSIGNED"
   }
  }
  ]

  # What disk/cdrom configuration will this have?
  disk_list = [{
    data_source_reference = [{
      kind = "image"
      uuid="${var.nat_template}"
    }]

    device_properties = [{
      disk_address {
        device_index = 0
        adapter_type = "SCSI"
      }

      device_type = "DISK"
    }]
  }
  ]
}

resource "nutanix_virtual_machine" "apache0_vm" {
  # General Information
  name                 = "${local.net_name}-apache0"
  num_vcpus_per_socket = 2
  num_sockets          = 1
  memory_size_mib      = 8192

  # What cluster will this VLAN live on?
  cluster_uuid = "${local.cluster1}"

guest_customization_cloud_init_user_data = "ZGlzYWJsZV9yb290OiBGYWxzZQpzc2hfZW5hYmxlZDogVHJ1ZQpzc2hfcHdhdXRoOiBUcnVl"

categories = [{
    "AppTier" = "WebTier"
  }]

project_reference {
    kind = "project",
    uuid = "${data.external.project_uuid.result["uuid"]}"
}
  # What networks will this be attached to?
  nic_list = [
  {
    subnet_uuid = "${nutanix_subnet.VPC.id}"

    ip_endpoint_list = {
         ip   = "${var.apache0_internal_ip}"
         type = "ASSIGNED"
   }
  }
  ]

  # What disk/cdrom configuration will this have?
  disk_list = [{
    data_source_reference = [{
      kind = "image"
      uuid="${var.apache0_template}"
    }]

    device_properties = [{
      disk_address {
        device_index = 0
        adapter_type = "SCSI"
      }

      device_type = "DISK"
    }]
  }
  ]
}

resource "nutanix_virtual_machine" "apache1_vm" {
  # General Information
  name                 = "${local.net_name}-apache1"
  num_vcpus_per_socket = 2
  num_sockets          = 1
  memory_size_mib      = 8192

  # What cluster will this VLAN live on?
  cluster_uuid = "${local.cluster1}"

guest_customization_cloud_init_user_data = "ZGlzYWJsZV9yb290OiBGYWxzZQpzc2hfZW5hYmxlZDogVHJ1ZQpzc2hfcHdhdXRoOiBUcnVl"

categories = [{
    "AppTier" = "WebTier"
  }]

project_reference {
    kind = "project",
    uuid = "${data.external.project_uuid.result["uuid"]}"
    }
  # What networks will this be attached to?
  nic_list = [
  {
    subnet_uuid = "${nutanix_subnet.VPC.id}"

    ip_endpoint_list = {
         ip   = "${var.apache1_internal_ip}"
         type = "ASSIGNED"
   }
  }
  ]

  # What disk/cdrom configuration will this have?
  disk_list = [{
    data_source_reference = [{
      kind = "image"
      uuid="${var.apache1_template}"
    }]

    device_properties = [{
      disk_address {
        device_index = 0
        adapter_type = "SCSI"
      }

      device_type = "DISK"
    }]
  }
  ]
}

resource "nutanix_virtual_machine" "mysql_vm" {
  # General Information
  name                 = "${local.net_name}-mysql"
  num_vcpus_per_socket = 2
  num_sockets          = 1
  memory_size_mib      = 8192

  # What cluster will this VLAN live on?
  cluster_uuid = "${local.cluster1}"

guest_customization_cloud_init_user_data = "ZGlzYWJsZV9yb290OiBGYWxzZQpzc2hfZW5hYmxlZDogVHJ1ZQpzc2hfcHdhdXRoOiBUcnVl"

categories = [{
    "AppTier" = "DBTier"
  }]

project_reference {
    kind = "project",
    uuid = "${data.external.project_uuid.result["uuid"]}"
}
  # What networks will this be attached to?
  nic_list = [
  {
    subnet_uuid = "${nutanix_subnet.VPC.id}"

    ip_endpoint_list = {
         ip   = "${var.mysql_internal_ip}"
         type = "ASSIGNED"
   }
  }
  ]

  # What disk/cdrom configuration will this have?
  disk_list = [{
    data_source_reference = [{
      kind = "image"
      uuid="${var.mysql_template}"
    }]

    device_properties = [{
      disk_address {
        device_index = 0
        adapter_type = "SCSI"
      }

      device_type = "DISK"
    }]
  }
  ]
}

# Show IP address
 output "haproxy ip" {
   value = "${lookup(nutanix_virtual_machine.haproxy_vm.nic_list_status.0.ip_endpoint_list[0], "ip")}"
 }
output "nat ip" {
   value = "${lookup(nutanix_virtual_machine.nat_vm.nic_list_status.0.ip_endpoint_list[0], "ip")}"
 }