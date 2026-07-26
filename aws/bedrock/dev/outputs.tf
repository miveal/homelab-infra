output "guardrail_id" {
  description = "Guardrail identifier for BEDROCK_GUARDRAIL_ID."
  value       = aws_bedrock_guardrail.ogrodniczy.guardrail_id
}

output "guardrail_version" {
  description = "Immutable numeric version for BEDROCK_GUARDRAIL_VERSION."
  value       = aws_bedrock_guardrail_version.ogrodniczy.version
}

output "guardrail_arn" {
  description = "Unversioned Ogrodniczy guardrail ARN."
  value       = aws_bedrock_guardrail.ogrodniczy.guardrail_arn
}

output "guardrail_arn_with_version" {
  description = "Versioned ARN for aws/identity/dev bedrock_guardrail_arn_version."
  value       = "${aws_bedrock_guardrail.ogrodniczy.guardrail_arn}:${aws_bedrock_guardrail_version.ogrodniczy.version}"
}
