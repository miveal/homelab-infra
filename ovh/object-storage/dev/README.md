# ovh/object-storage/dev — A62 voice cache bucket

OVH Object Storage (S3-compatible) for the A62 voice cache: backend-generated TTS audio
for encyclopedia/editorial content (Wiedza), cached so repeat requests don't
re-synthesize. First root module under `ovh/` in this repo.

**Creates:**

- `mojerodos-dev-voice` — S3 bucket, region `waw` (Warsaw), Standard storage class (the
  region/provider default — this resource has no bucket-level storage-class argument).
- A Public Cloud user scoped to the `objectstore_operator` OpenStack role — object
  storage only, not compute/network/volume.
- An S3 policy attached to that user restricting it to `mojerodos-dev-voice` only
  (list+location at the bucket, get+put on objects — no delete).

## Deliberately NOT here: S3 credentials

Terraform does **not** mint the `ovh_cloud_project_user_s3_credential` for this user —
its `secret_access_key` attribute would land in Terraform state in plaintext (the
`sensitive` flag only hides it from CLI/log output, not from the state file itself).
That would violate CLAUDE.md's "no secrets in ... anything state-readable," and two
precedents already in this repo resolve the same tension the same way: the
`aws/identity/dev` dev-app IAM user has its access key minted by hand so "the secret
never enters Terraform state," and `docs/agent-notes/cloudflare.md` states outright not
to add resources whose secret value would land in state without an explicit exception.

**Mint the credential by hand once, after apply:**

1. Read the `s3_user_id` output (or OVH Manager → Public Cloud project → Users).
2. OVH Manager: user → **Object Storage** tab → *Generate S3 credentials* — or via API:
   `POST /cloud/project/{serviceName}/user/{userId}/s3Credentials`.
3. Deliver the resulting `access_key_id` + `secret_access_key` to wherever the backend
   consumes them (homelab sops Secret, same pattern as `aws/identity/dev`'s
   `AWS_ACCESS_KEY_ID`/`AWS_SECRET_ACCESS_KEY` — see that root's README for the `sops
   set` command shape). Never paste them into this repo.

## DataClassification: `public` (today)

This bucket holds encyclopedia/editorial TTS audio — no personal data. **Slice-2**
chat-turn voice (Ogrodniczy advisor replies) IS personal data (tied to a user's
conversation) and is explicitly out of scope here; it needs its own RODO decision
(retention, deletion-on-request, very likely a separate bucket/prefix with per-user
access control) before it ships. Don't widen this bucket's policy to cover it.

## Apply

Via the normal repo flow: PR → CI `plan` → merge → prod-gated `apply`. No local apply —
agents are denied `terraform apply`/`destroy` (`.claude/settings.json`); this is the
human's step.

**Before the first apply, four repo secrets must exist** (Settings → Secrets and
variables → Actions): `OVH_APPLICATION_KEY`, `OVH_APPLICATION_SECRET`,
`OVH_CONSUMER_KEY`, `OVH_CLOUD_PROJECT_SERVICE`. See the PR description for exactly how
to generate each one (including the minimal-rights `createToken` URL for the consumer
key).

## Cost / class context

Standard-class OVH Object Storage is pay-as-you-go per GB stored + egress; a TTS cache
for editorial content is expected to stay small relative to the account's other spend.
No budget change requested here — revisit if the `aws/billing`-style anomaly signal
(this account doesn't have OVH billing alerting yet) suggests otherwise.
