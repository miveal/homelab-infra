# aws/bedrock/dev — Ogrodniczy Bedrock guardrail

Service-side safety configuration for the dev Ogrodniczy chat. IAM principals
and grants stay in `aws/identity/dev`.

This first published version is deliberately **detect mode**:

- Standard-tier prompt-attack and misconduct checks inspect text inputs and
  outputs with `input_action` / `output_action = "NONE"`.
- custom sensitive-information regexes detect AWS access keys, JWT-shaped
  values, and PEM private-key headers without blocking or rewriting content;
- the EU guardrail profile (`eu.guardrail.v1:0`) keeps evaluation inside its
  EU geographic boundary;
- no Bedrock model-invocation logging resource is created. Raw prompts and
  responses therefore are not copied to CloudWatch or S3 by this root.

Denied-topic detect actions are supported by the current Bedrock API but are
not yet exposed for `topics_config` by the locked AWS provider 6.56. The application-level
bounded scope classifier remains authoritative for gardening/app/internal/
cross-user categories. Do not turn topic blocking on until Polish false-positive
tests pass.

## Rollout

1. PR/CI plans this root; a human merges and approves the prod-gated apply.
2. Read `guardrail_id`, `guardrail_version`, and
   `guardrail_arn_with_version` from Terraform output.
3. Set backend deployment variables `BEDROCK_GUARDRAIL_ID` and
   `BEDROCK_GUARDRAIL_VERSION`.
4. Set `TF_VAR_bedrock_guardrail_arn_version` for `aws/identity/dev` to the
   versioned ARN and apply that root. Before this exact value is supplied,
   identity permits only a numeric version of a same-account,
   eu-central-1 guardrail; it still denies inference without a guardrail.
5. Observe trace-backed application audit flags and
   `mojerodos_ogrodniczy_scope_decisions_total`. Test Polish gardening,
   garden-safety, ordinary app-help, internal-system, and cross-user cases.
6. After review, change selected actions from `NONE` to `BLOCK`, add the denied
   topics when provider support is available, publish a new immutable version,
   and rotate the app/IAM configuration to that version.

Never use `DRAFT` in application configuration or IAM. Never enable model
invocation text logging from this root without a separate privacy/retention
decision.
