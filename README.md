# HabotConnect Associate Data Engineer Assessment

This repository contains a single, presentation-ready delivery package for the HabotConnect assessment. It brings together three workstreams:

1. Task 1 — infrastructure as code for a secure data landing zone in Google Cloud
2. Task 2 — a fail-closed CI/CD build gate for quality and security checks
3. Task 3 — a Django REST API for student onboarding data submission and validation

---

## Project Goal

The project demonstrates how to combine secure cloud infrastructure, automated quality gates, and a working backend service in one cohesive repository. The implementation focuses on least-privilege access, schema enforcement, validation, and reliable automation.

---

## Repository Structure

- .github/workflows/build-gate.yml — CI pipeline that runs linting, formatting, secret scanning, and build quarantine logic
- backend/ — Django app for onboarding submission, validation, and API logic
- backend/models.py — onboarding data model
- backend/serializers.py — request validation and business-rule enforcement
- backend/views.py — API endpoints for health checks and onboarding submissions
- backend/dcyn/logic.py — DCYN helper logic for Yes/No style fields
- backend/schema_mapping_sample_payload.json — sample payload for testing the API
- backend/demo_violation.py — intentionally insecure example used to demonstrate the build gate
- habotconnect/ — Django project settings and routing
- manage.py — Django entry point
- terraform/ — Terraform configuration for Task 1
- task1-terraform/task1-final/README.md — task-specific Terraform reference documentation

---

## Task 1 — Terraform: Secure Data Landing Zone

### What this task provides

The Terraform implementation provisions a secure, policy-aligned data platform in Google Cloud with two layers:

- D0 raw landing layer in Google Cloud Storage
- D1 staged and enforced layer in BigQuery

### Security controls included

- Customer-managed encryption keys (CMEK) with 90-day rotation
- Private GCS bucket with uniform bucket-level access and public access prevention
- Versioning and 30-day lifecycle deletion for bucket objects
- Time-bound IAM permissions for the pipeline service account
- Explicit BigQuery table schema to prevent silent schema drift
- Row-level security to hide rows flagged as containing direct PII from analysts

### Files involved

- terraform/main.tf — core Terraform resources
- terraform/variables.tf — input variables
- terraform/outputs.tf — output values
- terraform/terraform.tfvars — variable values

### How to run Task 1

Prerequisites:

- A Google Cloud project with billing enabled
- APIs enabled for Storage, BigQuery, and Cloud KMS
- Terraform 1.5 or newer
- A configured Google Cloud authentication context

Example flow:

```bash
terraform init
terraform validate
terraform plan
terraform apply
```

To remove the deployed resources:

```bash
terraform destroy
```

---

## Task 2 — CI/CD Build Gate

### Purpose

This task adds a fail-closed build gate to prevent weak or unsafe changes from being merged.

### What the pipeline checks

- Ruff for linting
- Black for formatting validation
- Gitleaks for secret scanning
- A quarantine step that blocks merges when checks fail

### Files involved

- .github/workflows/build-gate.yml — GitHub Actions workflow
- backend/demo_violation.py — example that intentionally violates expected conventions and is used to demonstrate the gate

### Why it matters

The build gate ensures that code quality, formatting standards, and secret hygiene are enforced automatically before changes can move forward.

---

## Task 3 — Django Onboarding API

### Purpose

The backend service exposes an API for student onboarding submissions and stores the accepted records locally in SQLite.

### API endpoints

- GET /api/health/ — returns service health status
- GET /api/student-onboarding/ — returns stored onboarding records
- POST /api/student-onboarding/ — submits a new onboarding record

### Validation rules

The API validates:

- required fields
- name formatting and length
- age range constraints
- phone number structure
- consent requirements
- DCYN-style Yes/No values for decision fields

### Local run instructions

1. Activate the Python virtual environment.
2. Apply migrations:

```bash
python manage.py migrate
```

3. Start the Django development server:

```bash
python manage.py runserver 127.0.0.1:8000
```

4. Test the health endpoint:

```bash
curl http://127.0.0.1:8000/api/health/
```

5. Submit a sample payload using the provided example file:

```bash
curl -X POST http://127.0.0.1:8000/api/student-onboarding/ \
  -H "Content-Type: application/json" \
  --data @backend/schema_mapping_sample_payload.json
```

---
