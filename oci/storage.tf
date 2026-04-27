resource "oci_objectstorage_bucket" "backup" {
  compartment_id = var.tenancy_ocid
  namespace      = data.oci_objectstorage_namespace.ns.namespace
  name           = "homelab-backup"
  access_type    = "NoPublicAccess"
  storage_tier   = "Standard"  # 10GB free; Archive tier na rzadszy dostęp
}
