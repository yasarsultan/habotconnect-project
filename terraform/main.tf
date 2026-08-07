terraform {
  required_version = ">= 1.5.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

provider "google-beta" {
  project = var.project_id
  region  = var.region
}

# ---------- CMEK ----------

resource "google_kms_key_ring" "keyring" {
  name     = "habotconnect-data-keyring"
  location = var.region
  project  = var.project_id
}

resource "google_kms_crypto_key" "key" {
  name            = "habotconnect-data-key"
  key_ring        = google_kms_key_ring.keyring.id
  rotation_period = "7776000s" # 90 days
  purpose         = "ENCRYPT_DECRYPT"

  lifecycle {
    prevent_destroy = true
  }
}

resource "google_project_service_identity" "gcs_sa" {
  provider = google-beta
  project  = var.project_id
  service  = "storage.googleapis.com"
}

resource "google_kms_crypto_key_iam_member" "gcs_sa_key_access" {
  crypto_key_id = google_kms_crypto_key.key.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:${google_project_service_identity.gcs_sa.email}"
}

resource "google_project_service_identity" "bq_sa" {
  provider = google-beta
  project  = var.project_id
  service  = "bigquery.googleapis.com"
}

resource "google_kms_crypto_key_iam_member" "bq_sa_key_access" {
  crypto_key_id = google_kms_crypto_key.key.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:${google_project_service_identity.bq_sa.email}"
}

# ---------- D0: Raw Landing (GCS) ----------

resource "google_storage_bucket" "d0_raw_landing" {
  name                        = var.raw_landing_bucket_name
  project                     = var.project_id
  location                    = var.region
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  versioning {
    enabled = true
  }

  lifecycle_rule {
    condition { age = 30 }
    action { type = "Delete" }
  }

  encryption {
    default_kms_key_name = google_kms_crypto_key.key.id
  }

  depends_on = [google_kms_crypto_key_iam_member.gcs_sa_key_access]
}

# Only the pipeline SA may write/read D0. No standing human access.
resource "google_storage_bucket_iam_member" "pipeline_write_d0" {
  bucket = google_storage_bucket.d0_raw_landing.name
  role   = "roles/storage.objectCreator"
  member = "serviceAccount:${var.pipeline_service_account_email}"

  condition {
    title      = "expires"
    expression = "request.time < timestamp(\"${var.iam_condition_expiry}\")"
  }
}

resource "google_storage_bucket_iam_member" "pipeline_read_d0" {
  bucket = google_storage_bucket.d0_raw_landing.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${var.pipeline_service_account_email}"

  condition {
    title      = "expires"
    expression = "request.time < timestamp(\"${var.iam_condition_expiry}\")"
  }
}

# ---------- D1: Staged/Enforced (BigQuery) ----------

resource "google_bigquery_dataset" "d1_staged_enforced" {
  dataset_id  = var.staged_dataset_id
  project     = var.project_id
  location    = var.bq_location
  description = "Schema-enforced layer populated only by the automated pipeline after validation."

  default_encryption_configuration {
    kms_key_name = google_kms_crypto_key.key.id
  }

  depends_on = [google_kms_crypto_key_iam_member.bq_sa_key_access]
}

resource "google_bigquery_table" "student_onboarding" {
  dataset_id          = google_bigquery_dataset.d1_staged_enforced.dataset_id
  table_id            = "student_onboarding"
  project             = var.project_id
  deletion_protection = true

  schema = jsonencode([
    { name = "student_id", type = "STRING", mode = "REQUIRED" },
    { name = "guardian_contact_info", type = "STRING", mode = "REQUIRED" },
    { name = "learning_support_needs", type = "STRING", mode = "NULLABLE" },
    { name = "onboarding_submitted_at", type = "TIMESTAMP", mode = "REQUIRED" },
    { name = "contains_direct_pii", type = "BOOLEAN", mode = "REQUIRED" }
  ])
}

# Row-level security: hide rows flagged as containing direct PII from
# the general analyst principal.
resource "google_bigquery_row_access_policy" "restrict_direct_pii" {
  project              = var.project_id
  dataset_id           = google_bigquery_dataset.d1_staged_enforced.dataset_id
  table_id             = google_bigquery_table.student_onboarding.table_id
  row_access_policy_id = "restrict_direct_pii"
  filter_predicate     = "contains_direct_pii = FALSE"
  grantees              = [var.analyst_principal]
}

# Pipeline writes, analyst only reads (subject to RLS above).
resource "google_bigquery_dataset_iam_member" "pipeline_write_d1" {
  dataset_id = google_bigquery_dataset.d1_staged_enforced.dataset_id
  project    = var.project_id
  role       = "roles/bigquery.dataEditor"
  member     = "serviceAccount:${var.pipeline_service_account_email}"

  condition {
    title      = "expires"
    expression = "request.time < timestamp(\"${var.iam_condition_expiry}\")"
  }
}

resource "google_bigquery_dataset_iam_member" "analyst_read_d1" {
  dataset_id = google_bigquery_dataset.d1_staged_enforced.dataset_id
  project    = var.project_id
  role       = "roles/bigquery.dataViewer"
  member     = var.analyst_principal
}
