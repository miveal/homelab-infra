locals {
  tags = {
    Project     = "mojerodos"
    Environment = "dev"
    Component   = "ses"
    ManagedBy   = "terraform"
    Repository  = "miveal/mojerodos-infra"
  }
}

# Dev configuration set. A config set does not reference the SES identity at the Terraform
# level (they link only at send time via ConfigurationSetName), so this leaf is independent of
# aws/ses/shared at apply time — apply order between them does not matter.
#
# The dev app must send with ConfigurationSetName = mojerodos-dev-ses; the IAM grant in
# aws/identity/dev scopes the dev principal to exactly this config set, isolating dev from a
# future mojerodos-prod-ses on the same shared identity.
resource "aws_sesv2_configuration_set" "this" {
  configuration_set_name = "mojerodos-dev-ses"

  delivery_options {
    tls_policy = "REQUIRE" # enforce TLS in transit
  }

  reputation_options {
    reputation_metrics_enabled = true # per-config-set bounce/complaint CloudWatch metrics
  }

  sending_options {
    sending_enabled = true
  }

  # Config-set-scoped suppression (on top of the account list in aws/ses/shared) — per-env,
  # isolated. Auto-suppresses addresses that bounce or complain.
  suppression_options {
    suppressed_reasons = ["BOUNCE", "COMPLAINT"]
  }

  tags = {
    Name               = "mojerodos-dev-ses"
    DataClassification = "personal-data" # the suppression list holds recipient addresses
  }
}

# Event destination -> CloudWatch. Chosen over SNS for dev: no extra topic/subscription/IAM,
# and bounce/complaint auto-suppression is already handled by the suppression lists. Surfaces
# send/delivery/bounce/complaint/reject counts as metrics. Prod upgrades this to SNS when a
# real feedback consumer exists.
resource "aws_sesv2_configuration_set_event_destination" "cw" {
  configuration_set_name = aws_sesv2_configuration_set.this.configuration_set_name
  event_destination_name = "mojerodos-dev-ses-cw"

  event_destination {
    enabled              = true
    matching_event_types = ["SEND", "DELIVERY", "BOUNCE", "COMPLAINT", "REJECT"]

    cloud_watch_destination {
      dimension_configuration {
        dimension_name          = "ses:configuration-set"
        dimension_value_source  = "MESSAGE_TAG"
        default_dimension_value = "mojerodos-dev-ses"
      }
    }
  }
}
