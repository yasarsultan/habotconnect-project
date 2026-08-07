variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region for the bucket and KMS key ring"
  type        = string
  default     = "us-central1"
}

variable "bq_location" {
  description = "BigQuery dataset location"
  type        = string
  default     = "US"
}

variable "raw_landing_bucket_name" {
  description = "Globally unique name for the D0 raw landing GCS bucket"
  type        = string
}

variable "staged_dataset_id" {
  description = "BigQuery dataset ID for the D1 staged/enforced layer"
  type        = string
  default     = "d1_staged_enforced"
}

variable "pipeline_service_account_email" {
  description = "Service account email for the automated pipeline (must already exist)"
  type        = string
}

variable "analyst_principal" {
  description = "Read-only principal for D1, e.g. 'group:analysts@company.com' or 'user:you@company.com'"
  type        = string
}

variable "iam_condition_expiry" {
  description = "RFC3339 timestamp after which the pipeline's write grants expire and must be reissued"
  type        = string
  default     = "2027-01-01T00:00:00Z"
}
