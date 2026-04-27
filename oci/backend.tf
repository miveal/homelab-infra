terraform {
  backend "oci" {
    bucket    = "homelab-tfstate"
    namespace = "https://frpbrwkcbszf.compat.objectstorage.eu-frankfurt-1.oraclecloud.com"
    key       = "oci/terraform.tfstate"
  }
}
