# Unit tests for the secure-bucket module.
# The AWS provider is mocked, so these tests need no credentials and create nothing.

mock_provider "aws" {}

variables {
  bucket_name = "claims-portal-test-documents"
}

run "blocks_all_public_access" {
  command = plan

  assert {
    condition = alltrue([
      aws_s3_bucket_public_access_block.this.block_public_acls,
      aws_s3_bucket_public_access_block.this.block_public_policy,
      aws_s3_bucket_public_access_block.this.ignore_public_acls,
      aws_s3_bucket_public_access_block.this.restrict_public_buckets,
    ])
    error_message = "All four S3 public access block settings must be enabled."
  }

  assert {
    condition     = one(aws_s3_bucket_ownership_controls.this.rule).object_ownership == "BucketOwnerEnforced"
    error_message = "ACLs must be disabled with BucketOwnerEnforced object ownership."
  }
}

run "encrypts_with_kms_by_default" {
  command = plan

  assert {
    condition     = one(aws_s3_bucket_server_side_encryption_configuration.this.rule).apply_server_side_encryption_by_default[0].sse_algorithm == "aws:kms"
    error_message = "Default encryption must use SSE-KMS."
  }

  assert {
    condition     = one(aws_s3_bucket_server_side_encryption_configuration.this.rule).bucket_key_enabled == true
    error_message = "S3 Bucket Keys must be enabled to reduce KMS cost."
  }
}

run "uses_customer_managed_key_when_provided" {
  command = plan

  variables {
    kms_key_arn = "arn:aws:kms:eu-central-1:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab"
  }

  assert {
    condition     = one(aws_s3_bucket_server_side_encryption_configuration.this.rule).apply_server_side_encryption_by_default[0].kms_master_key_id == var.kms_key_arn
    error_message = "The provided customer-managed KMS key must be used for default encryption."
  }
}

run "enables_versioning_by_default" {
  command = plan

  assert {
    condition     = aws_s3_bucket_versioning.this.versioning_configuration[0].status == "Enabled"
    error_message = "Versioning must be enabled by default."
  }
}

run "protects_against_accidental_deletion" {
  command = plan

  assert {
    condition     = aws_s3_bucket.this.force_destroy == false
    error_message = "force_destroy must default to false."
  }
}

run "rejects_invalid_bucket_name" {
  command = plan

  variables {
    bucket_name = "Claims_Documents"
  }

  expect_failures = [var.bucket_name]
}

run "rejects_non_kms_key_arn" {
  command = plan

  variables {
    kms_key_arn = "arn:aws:iam::111122223333:role/not-a-key"
  }

  expect_failures = [var.kms_key_arn]
}
