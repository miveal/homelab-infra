terraform {
  backend "oci" {
    bucket    = "homelab-tfstate"
    namespace = "frpbrwkcbszf"
    key       = "oci/terraform.tfstate"
  }
}
