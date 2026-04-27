resource "oci_core_vcn" "homelab" {
  compartment_id = var.tenancy_ocid
  cidr_blocks    = ["10.0.0.0/16"]
  display_name   = "homelab-vcn"
  dns_label      = "homelab"
}

resource "oci_core_internet_gateway" "igw" {
  compartment_id = var.tenancy_ocid
  vcn_id         = oci_core_vcn.homelab.id
  display_name   = "homelab-igw"
  enabled        = true
}

resource "oci_core_route_table" "public" {
  compartment_id = var.tenancy_ocid
  vcn_id         = oci_core_vcn.homelab.id
  display_name   = "public-rt"

  route_rules {
    destination       = "0.0.0.0/0"
    network_entity_id = oci_core_internet_gateway.igw.id
  }
}

resource "oci_core_security_list" "runner" {
  compartment_id = var.tenancy_ocid
  vcn_id         = oci_core_vcn.homelab.id
  display_name   = "runner-sl"

  # Outbound: wszystko dozwolone (GitHub API, apt, docker)
  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "all"
  }

  # Inbound: brak reguł = cały ruch przychodzący zablokowany
}

resource "oci_core_subnet" "public" {
  compartment_id    = var.tenancy_ocid
  vcn_id            = oci_core_vcn.homelab.id
  cidr_block        = "10.0.1.0/24"
  display_name      = "runner-subnet"
  dns_label         = "runners"
  route_table_id    = oci_core_route_table.public.id
  security_list_ids = [oci_core_security_list.runner.id]
}
