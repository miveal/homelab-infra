# OVH has no OIDC federation (CLAUDE.md), so auth is application key/secret + consumer
# key supplied out-of-band: in CI, GitHub repo secrets exposed as TF_VAR_ovh_* (see
# _terraform.yml); locally, exported the same way. Never committed, never in .tfvars.
#
# endpoint = "ovh-eu": the EU API endpoint, matching the EU data-residency convention
# (CLAUDE.md) and the WAW (Warsaw) bucket region below.
provider "ovh" {
  endpoint           = "ovh-eu"
  application_key    = var.ovh_application_key
  application_secret = var.ovh_application_secret
  consumer_key       = var.ovh_consumer_key
}
