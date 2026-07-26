# aws/identity/dev — dev app principal + EU-residency boundary

The dev environment's app identity on AWS: the principal the MojeRODos dev backend
authenticates as, its EU-residency permissions boundary, and its service grants. First live
caller: the Ogrodniczy advisor chat (hub epic agent#887 Wave B, core v1.59.0).

**Creates:**

- `mojerodos-dev-app-boundary` — EU-residency permissions boundary (the hard ceiling for
  every principal in this root; house convention is boundary, not SCP — standalone account,
  no Org).
- `mojerodos-dev-app-bedrock-invoke` — guardrail-required invocation grant: EU inference profiles +
  underlying foundation models, with an `aws:RequestedRegion eu-*` condition.
  Inference without a numeric same-account Ogrodniczy guardrail version is explicitly denied.
- `mojerodos-dev-app` — the static-key IAM user the k3s dev app authenticates as, with the
  boundary attached.

## Why a static-key user (stopgap)

The planned app-auth path for this component is **IAM Roles Anywhere** (trust anchor =
homelab CA) — the homelab cluster is NAT'd/outbound-only, so no instance or pod role is
possible. Roles Anywhere needs homelab-side CA + cert plumbing (novel infra, its own PR),
so this root ships a static-key user as an **explicit stopgap**: least privilege, EU pinned
twice (policy condition *and* boundary), key minted manually so the secret never enters
Terraform state. The user is retired when the Roles Anywhere role lands here.

## Deliberately NOT here

- **Bedrock guardrail policy** — it is the `bedrock/` component. This root owns the
  *principal and its grants* and only enforces that inference supplies the selected
  version. No model-invocation text logging is enabled.
- **Roles Anywhere** — see above.

## Apply

Via the normal repo flow: PR → CI `plan` → merge → prod-gated `apply`. No local apply.

Apply `aws/bedrock/dev` first. Then pass its `guardrail_arn_with_version` output as
`TF_VAR_bedrock_guardrail_arn_version` when planning/applying this root. The variable is
not a secret. If omitted during the first cross-component rollout, the policy still
requires a numeric version of a same-account eu-central-1 guardrail, but exact guardrail
selection is not locked until the output is supplied.

## Post-apply manual steps (human, has lead time)

1. **Bedrock model access** (console, eu-central-1 → *Model access*): enable
   **Amazon Nova Lite** (grounded chat turns) + **Anthropic Claude Haiku 4.5** (ungrounded
   turns — carries most Wave B traffic). Enable Claude Sonnet 4.6 + Opus 4.6 while there
   (bound for later waves; free until invoked). Anthropic requires a one-time use-case form.
2. **Mint the access key** (never via Terraform — keeps the secret out of state):
   `aws iam create-access-key --user-name mojerodos-dev-app` (or console → user →
   Security credentials).
3. **Deliver to the cluster** (homelab repo, sops-encrypted Secret; ArgoCD applies it and
   the Deployment's `envFrom` injects it):

   ```bash
   cd ~/rod_project/homelab
   sops set secrets/mojerodos-app-secrets.yaml '["stringData"]["AWS_ACCESS_KEY_ID"]' '"AKIA…"'
   sops set secrets/mojerodos-app-secrets.yaml '["stringData"]["AWS_SECRET_ACCESS_KEY"]' '"…"'
   git add secrets/mojerodos-app-secrets.yaml && git commit -m "feat(mojerodos-dev): Bedrock credentials" && git push
   ```

## Cost context

App-side spend control already exists (freeze-breaker $30/day / $300/month; per-user token
quota). The account-wide budget in `aws/billing` is **$20/month** — with Bedrock traffic
starting, its alerts will fire early by design; raising it is a human/billing decision, not
part of this root.
