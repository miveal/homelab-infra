locals {
  tags = {
    Project     = "mojerodos"
    Environment = "shared" # account-global: the apex identity is verified once, shared by every env
    Component   = "ses"
    ManagedBy   = "terraform"
    Repository  = "miveal/mojerodos-infra"
  }
}

# Apex domain identity for native SES sending. An SES email identity is unique per
# account+region, so the domain is verified ONCE here and shared across environments; dev and
# a future prod differ by configuration set + IAM scoping + sandbox/production access, not by
# separate identities. That's what lets prod onboard later without touching this root.
#
# No configuration_set_name is set on the identity ON PURPOSE — a default config set could
# only point at one env's set. Each env's principal passes ConfigurationSetName explicitly
# (dev = mojerodos-dev-ses), enforced by the IAM grant in aws/identity/<env>/.
#
# Easy DKIM: setting only next_signing_key_length hands key management to AWS (BYODKIM would
# add domain_signing_selector + domain_signing_private_key). The three CNAME tokens surface
# as an output for the cloudflare/dns follow-up PR.
resource "aws_sesv2_email_identity" "this" {
  email_identity = "mojerodos.pl"

  dkim_signing_attributes {
    next_signing_key_length = "RSA_2048_BIT"
  }

  tags = {
    Name               = "mojerodos-ses"
    DataClassification = "personal-data" # a sending path for RODO personal data
  }
}

# Custom MAIL FROM subdomain. Deliberately mail.mojerodos.pl, NOT send.mojerodos.pl — the
# latter is Resend's envelope subdomain (feedback-smtp.eu-west-1). Keeping them disjoint lets
# native SES coexist with Resend during the migration, then Resend's records retire cleanly.
# USE_DEFAULT_VALUE is tolerant during rollout (falls back to amazonses.com if the MX is not
# yet published); tighten to REJECT_MESSAGE once the DNS records are live and verified.
resource "aws_sesv2_email_identity_mail_from_attributes" "this" {
  email_identity         = aws_sesv2_email_identity.this.email_identity
  mail_from_domain       = "mail.mojerodos.pl"
  behavior_on_mx_failure = "USE_DEFAULT_VALUE"
}

# Account+region-scoped suppression list. This is a singleton per account+region (shared by
# dev and prod), so it belongs in this shared root, not duplicated in the per-env leaves.
# Config sets carry their own suppression on top (see aws/ses/dev).
resource "aws_sesv2_account_suppression_attributes" "this" {
  suppressed_reasons = ["BOUNCE", "COMPLAINT"]
}
