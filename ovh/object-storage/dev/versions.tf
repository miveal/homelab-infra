terraform {
  required_version = ">= 1.10.0"

  required_providers {
    ovh = {
      source  = "ovh/ovh"
      version = "~> 2.18"
    }
  }

  # Central state bucket from aws/bootstrap — backs ALL providers, OVH included, keyed
  # by provider (see CLAUDE.md). Backend auth is AWS OIDC (wired in the shared
  # _terraform.yml); OVH provider auth is separate (see providers.tf).
  backend "s3" {
    bucket       = "mojerodos-tfstate"
    key          = "ovh/object-storage/dev/terraform.tfstate"
    region       = "eu-central-1"
    encrypt      = true
    use_lockfile = true
  }
}
