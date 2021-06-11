data "nutanix_clusters" "clusters" {
  metadata = {
    length = 2
  }
}

output "cluster" {
  value = data.nutanix_clusters.clusters.entities.0.metadata.uuid
}

resource "nutanix_subnet" "next-iac-managed" {
  # What cluster will this VLAN live on?
  cluster_uuid = "${data.nutanix_clusters.clusters.entities.0.metadata.uuid}"

  # General Information
  name        = "next-iac-managed-example"
  vlan_id     = 101
  subnet_type = "VLAN"

  # Managed L3 Networks
  # This bit is only needed if you intend to turn on IPAM
  prefix_length = 20

  default_gateway_ip = "10.5.80.1"
  subnet_ip          = "10.5.80.0"

  dhcp_domain_name_server_list = ["8.8.8.8", "4.2.2.2"]
  dhcp_domain_search_list      = ["nutanix.com", "eng.nutanix.com"]
}