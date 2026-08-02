locals {
  bucket_name = "mojerodos-dev-voice"

  tags = {
    Project     = "mojerodos"
    Environment = "dev"
    Component   = "voice"
    ManagedBy   = "terraform"
    Repository  = "miveal/mojerodos-infra"
    # PUBLIC today: this bucket holds backend-generated TTS audio for encyclopedia /
    # editorial content (Wiedza) — no personal data, cached so repeat requests don't
    # re-synthesize. Slice-2 (Ogrodniczy advisor chat-turn voice replies) IS personal
    # data — it's tied to a user's conversation — and is explicitly OUT of scope for
    # this bucket. Slice-2 needs its own RODO decision (retention, deletion-on-request,
    # very likely a separate bucket/prefix with per-user access control) before it
    # ships. Do not widen this bucket's policy to cover Slice-2 audio without that
    # decision being made first.
    DataClassification = "public"
  }
}

# S3-compatible Object Storage bucket for the A62 voice cache. Single WAW (Warsaw)
# region. No bucket-level storage_class argument exists on this resource (verified
# against the live ovh/ovh provider docs — see docs/agent-notes/ovh.md); objects land
# on the Standard class unless a PUT explicitly requests otherwise via
# x-amz-storage-class, which the backend does not do today.
resource "ovh_cloud_project_storage" "voice" {
  service_name = var.ovh_cloud_project_service
  region_name  = "waw"
  name         = local.bucket_name

  tags = local.tags
}

# Public Cloud user scoped to object storage only (OpenStack/Keystone role, NOT
# compute/network/volume/etc) — first layer of least privilege. The second layer is
# the S3 policy below, which further restricts this specific user to THIS bucket only.
# NOTE: the ovh provider has no default_tags mechanism (unlike the aws provider) and
# this resource has no tags argument at all — description is the closest analogue.
resource "ovh_cloud_project_user" "voice" {
  service_name = var.ovh_cloud_project_service
  description  = "mojerodos-dev-voice — A62 voice cache backend (object storage only, scoped to ${local.bucket_name} via S3 policy)"
  role_names   = ["objectstore_operator"]
}

# Bucket-level restriction: this user's S3 credentials (minted manually — see README)
# can only touch mojerodos-dev-voice, nothing else in the project. Read: the backend
# presigns GETs for playback. Write: the backend uploads generated TTS audio. No
# Delete — cache entries are overwritten by key today, not pruned via this path; add
# s3:DeleteObject here if/when a cache-eviction job needs it.
resource "ovh_cloud_project_user_s3_policy" "voice" {
  service_name = var.ovh_cloud_project_service
  user_id      = ovh_cloud_project_user.voice.id

  policy = jsonencode({
    Statement = [
      {
        Sid      = "ListVoiceBucket"
        Effect   = "Allow"
        Action   = ["s3:ListBucket", "s3:GetBucketLocation"]
        Resource = ["arn:aws:s3:::${local.bucket_name}"]
      },
      {
        Sid      = "ReadWriteVoiceObjects"
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:PutObject"]
        Resource = ["arn:aws:s3:::${local.bucket_name}/*"]
      },
    ]
  })
}

# Deliberately NOT here: ovh_cloud_project_user_s3_credential.
#
# That resource's secret_access_key attribute would land in Terraform state in
# plaintext — Terraform's `sensitive` marking only redacts CLI/log output, it does not
# encrypt state content. The state bucket (mojerodos-tfstate) is private, but CLAUDE.md
# is stricter than "no secrets in outputs": "No secrets in .tfvars, variables, or
# anything state-readable." Two precedents already in this repo resolve the same
# tension the same way: aws/identity/dev's dev-app IAM user has its access key minted
# by hand (`aws iam create-access-key`) specifically so "the secret never enters
# Terraform state"; and docs/agent-notes/cloudflare.md states outright "Do not add
# ...resources whose secret value would land in state without the user explicitly
# accepting that exception."
#
# So: mint the S3 credential by hand (OVH Manager or API) against the `s3_user_id`
# output below — see README.md for the exact steps. If Dariusz would rather trade that
# for convenience, the ovh_cloud_project_user_s3_credential resource can be added later
# with an explicit note that it's an accepted exception.
