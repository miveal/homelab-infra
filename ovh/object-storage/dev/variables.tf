variable "ovh_cloud_project_service" {
  description = "OVH Public Cloud project ID (service_name) that owns the bucket and user. Not a credential, but project-identifying — supplied via the same TF_VAR_* secret lane as the OVH API keys for consistency (see PR description for the exact repo secret name)."
  type        = string
  sensitive   = true
}

variable "ovh_application_key" {
  description = "OVH API application key. Supplied as TF_VAR_ovh_application_key from a GitHub repo secret in CI, or exported locally. Never committed."
  type        = string
  sensitive   = true
}

variable "ovh_application_secret" {
  description = "OVH API application secret. Supplied as TF_VAR_ovh_application_secret from a GitHub repo secret in CI, or exported locally. Never committed."
  type        = string
  sensitive   = true
}

variable "ovh_consumer_key" {
  description = "OVH API consumer key, scoped to the minimal rights this root needs (storage + user management on this project only — see PR description for the exact createToken URL). Supplied as TF_VAR_ovh_consumer_key from a GitHub repo secret in CI, or exported locally. Never committed."
  type        = string
  sensitive   = true
}
