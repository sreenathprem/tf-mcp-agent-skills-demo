policytest {
  targets = ["s3-data-protection.policy.hcl"]
}

# Compliant: bucket with a full public access block and KMS encryption,
# as produced by modules/secure-bucket.

resource "aws_s3_bucket" "secure_documents" {
  attrs = {
    bucket = "claims-portal-dev-claims-documents"
  }
}

resource "aws_s3_bucket_public_access_block" "secure_documents" {
  attrs = {
    bucket                  = "claims-portal-dev-claims-documents"
    block_public_acls       = true
    block_public_policy     = true
    ignore_public_acls      = true
    restrict_public_buckets = true
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "secure_documents" {
  attrs = {
    bucket = "claims-portal-dev-claims-documents"
    rule = [{
      bucket_key_enabled = true
      apply_server_side_encryption_by_default = [{
        sse_algorithm     = "aws:kms"
        kms_master_key_id = null
      }]
    }]
  }
}

# Non-compliant companion resources

resource "aws_s3_bucket_public_access_block" "partially_open" {
  expect_failure = true
  attrs = {
    bucket                  = "claims-portal-dev-claims-documents"
    block_public_acls       = true
    block_public_policy     = false
    ignore_public_acls      = true
    restrict_public_buckets = false
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "aes256_only" {
  expect_failure = true
  attrs = {
    bucket = "claims-portal-dev-claims-documents"
    rule = [{
      bucket_key_enabled = false
      apply_server_side_encryption_by_default = [{
        sse_algorithm     = "AES256"
        kms_master_key_id = null
      }]
    }]
  }
}
