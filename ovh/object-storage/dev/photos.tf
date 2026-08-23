locals {
  photos_bucket_name = "mojerodos-dev-photos"

  photos_tags = {
    Project     = "mojerodos"
    Environment = "dev"
    Component   = "photos"
    ManagedBy   = "terraform"
    Repository  = "miveal/mojerodos-infra"
    # PERSONAL: this bucket holds user-uploaded photos (A64 photo asset model) —
    # user-generated content bound to accounts. Deletion paths are implemented
    # backend-side and are the authoritative eraser: hard delete on
    # DELETE /api/photos/{id} (A64 §11.1 AC-23) and the Art.17 account-purge
    # 3-cohort gate (core#968 AC-25). The `photos` DB table is the authoritative
    # list of keys to delete — no bucket policies, no S3 events, no lifecycle
    # rules here by design (a64/infra-storage P3: lifecycle is app-driven).
    # Dev-only caveat: through v2.x this bucket holds disposable test data
    # (project data-loss convention); the classification is still `personal`
    # because the PIPELINE is the prod pipeline.
    DataClassification = "personal"
  }
}

# S3-compatible Object Storage bucket for A64 user photos (dev). Single WAW
# (Warsaw) region — same residency decision as prod (agent#931 ratified
# OVH-Warsaw as the app-data object-storage home). Standard class by default;
# no bucket-level storage_class argument exists on this resource (see the
# voice bucket note above / docs/agent-notes/ovh.md).
#
# Naming: sibling-consistent with `mojerodos-dev-voice` (env-prefix style).
# NOTE the deliberate divergence from the k3s MinIO dev bucket this replaces
# (`mojerodos-photos-dev`, homelab#106) — the backend's PHOTO_STORAGE_BUCKET
# env is set per-deploy, so the name difference is config, not code.
resource "ovh_cloud_project_storage" "photos" {
  service_name = var.ovh_cloud_project_service
  region_name  = "WAW" # control-plane region codes are UPPERCASE; the S3 endpoint hostname keeps lowercase waw
  name         = local.photos_bucket_name

  tags = local.photos_tags
}

# Public Cloud user scoped to object storage only — same two-layer least
# privilege as the voice user: OpenStack role first, bucket-scoped S3 policy
# second.
resource "ovh_cloud_project_user" "photos" {
  service_name = var.ovh_cloud_project_service
  description  = "mojerodos-dev-photos — A64 user-photo storage backend (object storage only, scoped to ${local.photos_bucket_name} via S3 policy)"
  role_names   = ["objectstore_operator"]
}

# Bucket-level restriction: this user's S3 credentials (minted manually — see
# README) can only touch mojerodos-dev-photos. Unlike the voice policy, this
# one INCLUDES s3:DeleteObject — deletion is a first-class product path here:
# hard delete (A64 AC-23), the Art.17 purge (core#968 AC-25), and the B4
# moderation object moves (quarantine/block relocation = server-side
# CopyObject + DeleteObject, core#969 AC-M7b/AC-M32). CopyObject within the
# bucket is covered by GetObject (source) + PutObject (destination).
resource "ovh_cloud_project_user_s3_policy" "photos" {
  service_name = var.ovh_cloud_project_service
  user_id      = ovh_cloud_project_user.photos.id

  policy = jsonencode({
    Statement = [
      {
        Sid      = "ListPhotosBucket"
        Effect   = "Allow"
        Action   = ["s3:ListBucket", "s3:GetBucketLocation"]
        Resource = ["arn:aws:s3:::${local.photos_bucket_name}"]
      },
      {
        Sid      = "ReadWriteDeletePhotosObjects"
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
        Resource = ["arn:aws:s3:::${local.photos_bucket_name}/*"]
      },
    ]
  })
}

# Deliberately NOT here: ovh_cloud_project_user_s3_credential — same
# secret-never-enters-state rule as the voice user (see the long note in
# main.tf and README §"Deliberately NOT here"). Mint the credential by hand
# against the `photos_s3_user_id` output, then deliver it to the homelab sops
# Secret `mojerodos-ovh-photos-s3` (placeholder PR opened alongside this one).
