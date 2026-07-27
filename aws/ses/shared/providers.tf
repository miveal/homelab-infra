# SES is a regional service. eu-central-1 is the account home region (state bucket,
# identity/dev, planned Bedrock) — keep the whole account in one EU region for RODO.
# The MAIL FROM MX and DKIM CNAMEs are region-specific (feedback-smtp.eu-central-1.amazonses.com).
provider "aws" {
  region = "eu-central-1"

  default_tags {
    tags = local.tags
  }
}
