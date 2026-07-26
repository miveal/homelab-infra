variable "bedrock_guardrail_arn_version" {
  description = "Exact versioned ARN from aws/bedrock/dev. Null allows any numeric same-account eu-central-1 guardrail version for first rollout."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition = var.bedrock_guardrail_arn_version == null || can(regex(
      "^arn:aws:bedrock:eu-central-1:[0-9]{12}:guardrail/[a-z0-9]+:[1-9][0-9]*$",
      var.bedrock_guardrail_arn_version,
    ))
    error_message = "bedrock_guardrail_arn_version must be a numeric eu-central-1 guardrail ARN, never DRAFT."
  }
}
