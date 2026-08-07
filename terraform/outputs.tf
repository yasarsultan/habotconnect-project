output "d0_bucket_url" {
  value = google_storage_bucket.d0_raw_landing.url
}

output "d1_dataset_id" {
  value = "${var.project_id}:${google_bigquery_dataset.d1_staged_enforced.dataset_id}"
}

output "d1_table_id" {
  value = "${var.project_id}:${google_bigquery_dataset.d1_staged_enforced.dataset_id}.${google_bigquery_table.student_onboarding.table_id}"
}

output "kms_key_id" {
  value = google_kms_crypto_key.key.id
}
