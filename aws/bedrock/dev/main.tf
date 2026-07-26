locals {
  tags = {
    Project     = "mojerodos"
    Environment = "dev"
    Component   = "bedrock"
    ManagedBy   = "terraform"
    Repository  = "miveal/mojerodos-infra"
  }
}

data "aws_caller_identity" "current" {}

resource "aws_bedrock_guardrail" "ogrodniczy" {
  name                      = "mojerodos-dev-ogrodniczy"
  description               = "Detect-mode defense in depth for Ogrodniczy gardening and ordinary app-help chat."
  blocked_input_messaging   = "Mogę pomóc tylko w sprawach ogrodniczych i w korzystaniu z funkcji aplikacji dostępnych dla Twojego konta."
  blocked_outputs_messaging = "Mogę pomóc tylko w sprawach ogrodniczych i w korzystaniu z funkcji aplikacji dostępnych dla Twojego konta."

  cross_region_config {
    guardrail_profile_identifier = "arn:aws:bedrock:eu-central-1:${data.aws_caller_identity.current.account_id}:guardrail-profile/eu.guardrail.v1:0"
  }

  content_policy_config {
    tier_config = [{ tier_name = "STANDARD" }]

    filters_config {
      type              = "PROMPT_ATTACK"
      input_strength    = "HIGH"
      output_strength   = "NONE"
      input_action      = "NONE"
      output_action     = "NONE"
      input_enabled     = true
      output_enabled    = false
      input_modalities  = ["TEXT"]
      output_modalities = ["TEXT"]
    }

    filters_config {
      type              = "MISCONDUCT"
      input_strength    = "MEDIUM"
      output_strength   = "MEDIUM"
      input_action      = "NONE"
      output_action     = "NONE"
      input_enabled     = true
      output_enabled    = true
      input_modalities  = ["TEXT"]
      output_modalities = ["TEXT"]
    }
  }

  sensitive_information_policy_config {
    regexes_config {
      name           = "aws-access-key"
      description    = "AWS access-key identifiers."
      pattern        = "\\b(?:AKIA|ASIA)[A-Z0-9]{16}\\b"
      action         = "NONE"
      input_action   = "NONE"
      output_action  = "NONE"
      input_enabled  = true
      output_enabled = true
    }

    regexes_config {
      name           = "jwt-shaped-token"
      description    = "Three-segment JWT-shaped bearer values."
      pattern        = "eyJ[A-Za-z0-9_-]{8,}\\.[A-Za-z0-9_-]{8,}\\.[A-Za-z0-9_-]{8,}"
      action         = "NONE"
      input_action   = "NONE"
      output_action  = "NONE"
      input_enabled  = true
      output_enabled = true
    }

    regexes_config {
      name           = "pem-private-key"
      description    = "PEM private-key headers."
      pattern        = "-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----"
      action         = "NONE"
      input_action   = "NONE"
      output_action  = "NONE"
      input_enabled  = true
      output_enabled = true
    }
  }

  tags = {
    Name               = "mojerodos-dev-ogrodniczy"
    DataClassification = "internal-policy"
  }
}

resource "aws_bedrock_guardrail_version" "ogrodniczy" {
  guardrail_arn = aws_bedrock_guardrail.ogrodniczy.guardrail_arn
  description   = "Ogrodniczy detect-mode baseline: prompt attack, misconduct, and secret-pattern detection."
  skip_destroy  = true
}
