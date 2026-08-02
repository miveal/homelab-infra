# OVH

**Status:** partial — `ovh/object-storage/dev/` BUILT (branch `feat/ovh-voice-object-storage`), not applied
**Verified as of:** 2026-08-02 on commit `564f912`
**Owner of scope (in repo):** `ovh/` (Terraform root modules)

## What this covers
All OVH Terraform: root modules under `ovh/` and any OVH-specific shared modules.
Provider auth, state backend for OVH (shared `mojerodos-tfstate` S3 bucket, see [[aws]]),
compute/network/storage resources. Does NOT cover Cloudflare DNS that points at OVH
hosts — that's the [[cloudflare]] scope.

## Current state
- **`ovh/object-storage/dev/`** — BUILT 2026-08-02 (branch `feat/ovh-voice-object-storage`),
  not applied. First OVH root module. Creates the A62 voice-cache bucket
  `mojerodos-dev-voice` (region `waw`/Warsaw, Standard class), a Public Cloud user scoped
  to `objectstore_operator`, and an S3 policy restricting that user to read+write on this
  bucket only. Deliberately does NOT mint S3 credentials via Terraform (see Decisions).
  `fmt`/`validate` green (`terraform init -backend=false`). Refs
  bobr-pro/mojerodos-agent#974, bobr-pro/mojerodos-core#730.
- `.github/workflows/ovh.yml` — new changed-leaf-matrix caller, same shape as
  `cloudflare.yml` (no bootstrap to exclude). `.github/workflows/_terraform.yml` extended
  with four optional OVH secrets (`ovh_application_key`, `ovh_application_secret`,
  `ovh_consumer_key`, `ovh_cloud_project_service`) → `TF_VAR_ovh_*`, mirroring the
  `cloudflare_api_token` pattern. See [[ci]].

## Conventions specific to this scope
- Pin the OVH provider version in `versions.tf` with `~>` (currently `~> 2.18`, matching
  the latest `ovh/ovh` release at authoring time — verify against
  `https://github.com/ovh/terraform-provider-ovh/releases` before bumping blind).
- OVH API credentials (application key/secret/consumer key) + the Public Cloud project ID
  (`service_name`) come from GitHub Actions repo secrets, exposed as `TF_VAR_ovh_*` — never
  committed, never in `.tfvars`. Provider block: `endpoint = "ovh-eu"` (EU residency).
- One root module = one provider = one state file, `ovh/<component>/<env>/`, backed by the
  shared `mojerodos-tfstate` bucket (same as every other provider — see CLAUDE.md).
- **No secrets in state, full stop — stricter than "no secrets in outputs".** The
  `ovh_cloud_project_user_s3_credential` resource's `secret_access_key` is provider-marked
  `sensitive` but that only redacts CLI/log output, not state content. Mint S3 credentials
  by hand (OVH Manager → user → Object Storage tab, or
  `POST /cloud/project/{serviceName}/user/{userId}/s3Credentials`) against the Terraform
  user resource's `id` output, and deliver them out-of-band (homelab sops Secret) — same
  shape as `aws/identity/dev`'s manually-minted AWS access key.
- The `ovh` provider has **no `default_tags` mechanism** (unlike `aws`). `ovh_cloud_project_storage`
  does have a `tags` map argument — set it per-resource. `ovh_cloud_project_user` and
  `ovh_cloud_project_user_s3_policy` have no tags argument at all; use `description` on
  the user as the closest analogue.
- `ovh_cloud_project_storage` (the bucket resource) has no bucket-level `storage_class`
  argument — the region code alone (e.g. `waw`) doesn't pin a class; objects default to
  Standard unless a PUT sets `x-amz-storage-class` explicitly.
- `ovh_cloud_project_user` always returns a sensitive OpenStack `password` attribute on
  creation, even if unused/unreferenced — this lands in state as an unavoidable side
  effect of creating the resource at all (there's no OVH-side way to create a Public
  Cloud user without Keystone minting a password). Distinct from the S3 credential
  question above; flag it in any PR that creates this resource type.

## Open questions / pending decisions
- Whether self-hosted runners get rebuilt on OVH (the OCI version was removed) — still
  open, unrelated to the voice-storage work.
- Whether Dariusz wants the `ovh_cloud_project_user_s3_credential` convenience trade-off
  (secret in state) instead of the manual-mint path — default is manual-mint per repo
  convention; revisit only if he explicitly asks.
- Slice-2 (Ogrodniczy chat-turn voice, personal data) needs its own RODO decision + very
  likely a separate bucket/prefix before it ships — tracked as a comment in
  `ovh/object-storage/dev/main.tf`, not yet a ticket.

## Recent changes log
- 2026-08-02 (`564f912`, branch `feat/ovh-voice-object-storage`): built
  `ovh/object-storage/dev/` (bucket + scoped user + S3 policy, no TF-managed credential),
  wired `ovh.yml` + extended `_terraform.yml` with the four OVH secrets. `fmt`/`validate`
  green via `init -backend=false`. Not applied — PR opened, not merged.
- 2026-06-08 (`87a5a89`): scope created; OCI removed from the repo; OVH chosen as first
  new provider. No OVH Terraform written yet at that point.

## Gotchas
- Editing `.github/workflows/_terraform.yml` re-runs every provider's leaves on the next
  push to `main` (documented in [[ci]]) — this PR touches it, so expect AWS + Cloudflare
  leaves to re-plan/re-apply alongside the new OVH leaf on merge.
- `registry.terraform.io` resource-doc pages are JS-rendered SPAs — WebFetch against them
  returns only the page shell. Use the raw GitHub source instead:
  `raw.githubusercontent.com/ovh/terraform-provider-ovh/master/docs/resources/<name>.md`
  (default branch is `master`, not `main`).
