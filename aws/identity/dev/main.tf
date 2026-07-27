locals {
  tags = {
    Project     = "mojerodos"
    Environment = "dev"
    Component   = "identity"
    ManagedBy   = "terraform"
    Repository  = "miveal/mojerodos-infra"
  }
}

# Bedrock invocation grant for the dev app principal (first caller: Ogrodniczy advisor
# chat, agent#887 Wave B).
# The Converse / ConverseStream APIs authorize as bedrock:InvokeModel(+WithResponseStream).
# Cross-region inference: a call on an eu.* geographic inference profile authorizes against
# BOTH the profile ARN and the underlying per-region foundation-model ARNs — both stanzas
# are required or CRIS calls fail with AccessDenied.
# aws:RequestedRegion eu-* is the RODO data-residency guardrail: standalone account, no
# Org/SCP available, so EU-only is enforced at the principal (here + the boundary below).
data "aws_iam_policy_document" "bedrock_invoke_eu" {
  statement {
    sid = "InvokeEUProfilesOnly"

    actions = [
      "bedrock:InvokeModel",
      "bedrock:InvokeModelWithResponseStream",
    ]

    resources = [
      "arn:aws:bedrock:*:*:inference-profile/eu.*",
      "arn:aws:bedrock:*::foundation-model/*",
    ]

    condition {
      test     = "StringLike"
      variable = "aws:RequestedRegion"
      values   = ["eu-*"]
    }
  }

  # bedrock-mantle endpoint (bedrock-mantle.<region>.api.aws) — a SEPARATE IAM namespace
  # from bedrock:* (probe-verified 2026-07-17: the denial cited bedrock-mantle:ListModels
  # on project/default and named this boundary — the ceiling worked as designed).
  # CreateInference covers all three API surfaces the endpoint serves (OpenAI Responses,
  # OpenAI Chat Completions, Anthropic Messages); ListModels covers GET /v1/models.
  # bedrock-mantle:CallWithBearerToken is deliberately NOT granted — SigV4 only, no
  # Bedrock API keys for this principal. Same eu-* residency condition as above; note the
  # mantle Responses API stores conversations 30 days by DEFAULT (store:true) — any app
  # use must set store:false or use the stateless Messages/Chat Completions surfaces.
  statement {
    sid = "MantleEUInferenceOnly"

    actions = [
      "bedrock-mantle:CreateInference",
      "bedrock-mantle:ListModels",
    ]

    resources = [
      "arn:aws:bedrock-mantle:*:*:project/*",
    ]

    condition {
      test     = "StringLike"
      variable = "aws:RequestedRegion"
      values   = ["eu-*"]
    }
  }
}

resource "aws_iam_policy" "bedrock_invoke_eu" {
  name   = "mojerodos-dev-app-bedrock-invoke"
  policy = data.aws_iam_policy_document.bedrock_invoke_eu.json

  tags = { Name = "mojerodos-dev-app-bedrock-invoke" }
}

# SES send grant for the dev app principal (native SES sending from mojerodos.pl).
# The apex identity + config set live in other roots (aws/ses/shared, aws/ses/dev); IAM does
# not validate resource existence, so the ARNs are constructed by string here — no
# terraform_remote_state, and this is valid regardless of ses/* apply order (the CI leaf
# matrix sorts alphabetically and cannot express cross-leaf ordering).
# Resources are scoped to BOTH the identity AND the dev config set: SendEmail with a
# ConfigurationSetName authorizes against both ARNs, so pinning to mojerodos-dev-ses isolates
# the dev principal from a future mojerodos-prod-ses on the same shared identity.
# aws:RequestedRegion eu-* is the same RODO residency guardrail applied to the Bedrock grant.
data "aws_iam_policy_document" "ses_send_eu" {
  statement {
    sid = "SendFromApexViaDevConfigSet"

    actions = [
      "ses:SendEmail",
      "ses:SendRawEmail",
    ]

    resources = [
      "arn:aws:ses:eu-central-1:474939505073:identity/mojerodos.pl",
      "arn:aws:ses:eu-central-1:474939505073:configuration-set/mojerodos-dev-ses",
    ]

    condition {
      test     = "StringLike"
      variable = "ses:FromAddress"
      values   = ["*@mojerodos.pl"]
    }

    condition {
      test     = "StringLike"
      variable = "aws:RequestedRegion"
      values   = ["eu-*"]
    }
  }
}

resource "aws_iam_policy" "ses_send_eu" {
  name   = "mojerodos-dev-app-ses-send"
  policy = data.aws_iam_policy_document.ses_send_eu.json

  tags = { Name = "mojerodos-dev-app-ses-send" }
}

# EU-residency permissions boundary — the hard ceiling for every principal in this root
# (the planned Roles Anywhere role included, not just today's user). Even if a broader policy
# is attached later, effective permissions stay capped at EU-only Bedrock invocation + SES
# send. The boundary is the UNION of the service grants (Bedrock + SES), keeping the eu-*
# region condition on every statement — as foretold when only Bedrock was granted: "widens by
# service but keeps the eu-* region condition." grant ∩ boundary still equals the grant.
# SES resources are "*" here because the boundary is only a ceiling; the ses_send_eu grant
# above does the resource/FromAddress scoping.
data "aws_iam_policy_document" "app_boundary" {
  source_policy_documents = [data.aws_iam_policy_document.bedrock_invoke_eu.json]

  statement {
    sid = "BoundarySESSendEU"

    actions = [
      "ses:SendEmail",
      "ses:SendRawEmail",
    ]

    resources = ["*"]

    condition {
      test     = "StringLike"
      variable = "aws:RequestedRegion"
      values   = ["eu-*"]
    }
  }
}

resource "aws_iam_policy" "app_boundary" {
  name   = "mojerodos-dev-app-boundary"
  policy = data.aws_iam_policy_document.app_boundary.json

  tags = { Name = "mojerodos-dev-app-boundary" }
}

# Static-key programmatic user for the k3s dev app — STOPGAP until this root grows the
# planned IAM Roles Anywhere path (trust anchor = homelab CA); the homelab cluster is
# NAT'd/outbound-only, so no instance/pod role is possible. The access key is minted
# MANUALLY (see README) so the secret never enters Terraform state; it reaches the cluster
# via the sops-encrypted Secret in the homelab repo.
resource "aws_iam_user" "app" {
  name                 = "mojerodos-dev-app"
  permissions_boundary = aws_iam_policy.app_boundary.arn

  tags = { Name = "mojerodos-dev-app" }
}

resource "aws_iam_user_policy_attachment" "app_bedrock_invoke" {
  user       = aws_iam_user.app.name
  policy_arn = aws_iam_policy.bedrock_invoke_eu.arn
}

resource "aws_iam_user_policy_attachment" "app_ses_send" {
  user       = aws_iam_user.app.name
  policy_arn = aws_iam_policy.ses_send_eu.arn
}
