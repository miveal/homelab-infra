# VCN
resource "oci_core_vcn" "homelab" {
  compartment_id = var.tenancy_ocid
  cidr_blocks    = ["10.0.0.0/16"]
  display_name   = "homelab-vcn"
  dns_label      = "homelab"
}

# Gateways
resource "oci_core_internet_gateway" "igw" {
  compartment_id = var.tenancy_ocid
  vcn_id         = oci_core_vcn.homelab.id
  display_name   = "homelab-igw"
  enabled        = true
}

resource "oci_core_nat_gateway" "nat" {
  compartment_id = var.tenancy_ocid
  vcn_id         = oci_core_vcn.homelab.id
  display_name   = "homelab-nat"
}

resource "oci_core_service_gateway" "sgw" {
  compartment_id = var.tenancy_ocid
  vcn_id         = oci_core_vcn.homelab.id
  display_name   = "homelab-sgw"

  services {
    service_id = data.oci_core_services.all.services[0].id # "All <region> Services In Oracle Services Network"
  }
}

# Route table — prywatna: NAT dla internetu, SGW dla OCI serwisów
resource "oci_core_route_table" "private" {
  compartment_id = var.tenancy_ocid
  vcn_id         = oci_core_vcn.homelab.id
  display_name   = "private-rt"

  route_rules {
    destination       = "0.0.0.0/0"
    network_entity_id = oci_core_nat_gateway.nat.id
  }

  route_rules {
    destination_type  = "SERVICE_CIDR_BLOCK"
    destination       = data.oci_core_services.all.services[0].cidr_block
    network_entity_id = oci_core_service_gateway.sgw.id
  }
}

# Security list — tylko outbound, zero inbound
resource "oci_core_security_list" "private" {
  compartment_id = var.tenancy_ocid
  vcn_id         = oci_core_vcn.homelab.id
  display_name   = "private-sl"

  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "all"
  }
  # Brak ingress rules — OCI Bastion tworzy własny tunel SSH
}

# Prywatna subnet
resource "oci_core_subnet" "private" {
  compartment_id             = var.tenancy_ocid
  vcn_id                     = oci_core_vcn.homelab.id
  cidr_block                 = "10.0.1.0/24"
  display_name               = "private-subnet"
  dns_label                  = "private"
  prohibit_public_ip_on_vnic = true # <-- wymusza brak public IP
  route_table_id             = oci_core_route_table.private.id
  security_list_ids          = [oci_core_security_list.private.id]
}

# OCI Bastion (Always Free: 5 sesji, SSH on-demand)
resource "oci_bastion_bastion" "homelab" {
  compartment_id               = var.tenancy_ocid
  bastion_type                 = "STANDARD"
  name                         = "homelab-bastion"
  target_subnet_id             = oci_core_subnet.private.id
  client_cidr_block_allow_list = [var.bastion_allowed_cidr] # Twoje IP lub "0.0.0.0/0"
  max_session_ttl_in_seconds   = 10800                      # 3h
}