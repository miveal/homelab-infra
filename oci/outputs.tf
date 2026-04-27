output "runner_instance_ocids" {
  description = "OCIDy instancji GitHub runnerów — wklej do OCI_RUNNER_INSTANCE_OCIDS secret"
  value       = join(" ", oci_core_instance.github_runner[*].id)
}

output "runner_names" {
  description = "Nazwy runnerów widoczne w GitHub Actions"
  value       = oci_core_instance.github_runner[*].display_name
}

output "bastion_id" {
  description = "OCID Bastionu do sesji SSH"
  value       = oci_bastion_bastion.homelab.id
}

output "tfstate_backend_endpoint" {
  description = "Gotowy endpoint do backend S3 w providers.tf"
  value       = "https://${data.oci_objectstorage_namespace.ns.namespace}.compat.objectstorage.${var.region}.oraclecloud.com"
}
