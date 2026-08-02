output "bucket_name" {
  description = "OVH Object Storage bucket name for the A62 voice cache."
  value       = ovh_cloud_project_storage.voice.name
}

output "bucket_endpoint" {
  description = "S3-compatible endpoint host for the WAW region. Use virtual-host style (https://<bucket>.s3.waw.io.cloud.ovh.net) or path-style against this host."
  value       = "https://s3.waw.io.cloud.ovh.net"
}

output "bucket_virtual_host" {
  description = "Bucket-specific virtual host, as reported live by OVH."
  value       = ovh_cloud_project_storage.voice.virtual_host
}

output "s3_user_id" {
  description = "OVH Public Cloud user ID scoped to this bucket. Use this to mint S3 credentials manually (see README) — never via Terraform, so the secret access key never enters state."
  value       = ovh_cloud_project_user.voice.id
}

output "s3_user_username" {
  description = "OVH-generated username for the scoped object-storage user (OpenStack identity, informational only — S3 auth uses the access key/secret pair minted manually, not this)."
  value       = ovh_cloud_project_user.voice.username
}
