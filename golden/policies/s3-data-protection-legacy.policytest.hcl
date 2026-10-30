# Kept in its own file: core::getresources() sees every mock in a test file,
# so the "no companion resources" scenario must not share a file with the
# compliant bucket.

policytest {
  targets = ["s3-data-protection.policy.hcl"]
}

# The legacy claims documents bucket: no public access block, no encryption.
resource "aws_s3_bucket" "legacy_claims_documents" {
  expect_failure = true
  attrs = {
    bucket = "acme-claims-documents-prod"
  }
}
