output "configuration_set_name" {
  description = "Dev config set (TLS-required, reputation metrics, bounce+complaint suppression). Pass as ConfigurationSetName when the dev app sends."
  value       = aws_sesv2_configuration_set.this.configuration_set_name
}

output "configuration_set_arn" {
  description = "ARN of the dev config set. Referenced by string in the aws/identity/dev send grant."
  value       = aws_sesv2_configuration_set.this.arn
}
