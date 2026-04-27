terraform {
  backend "s3" {
    # OCI Object Storage kompatybilny z S3 API
    bucket                      = "homelab-tfstate"
    key                         = "oci/terraform.tfstate"
    region                      = "eu-frankfurt-1"
    endpoint                    = "https://frpbrwkcbszf.compat.objectstorage.eu-frankfurt-1.oraclecloud.com"
    skip_region_validation      = true
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    force_path_style            = true
  }
}
