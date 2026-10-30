# secure-bucket

S3 bucket with secure defaults:

- Public access blocked at bucket level, ACLs disabled (`BucketOwnerEnforced`)
- Default encryption with SSE-KMS and S3 Bucket Keys (AWS-managed key or a customer-managed key)
- Versioning enabled
- Bucket policy that denies non-TLS requests

## Usage

```hcl
module "documents_bucket" {
  source = "./modules/secure-bucket"

  bucket_name = "claims-portal-dev-claims-documents"
  kms_key_arn = aws_kms_key.documents.arn # optional
}
```

## Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `bucket_name` | Globally unique name of the S3 bucket | `string` | n/a |
| `force_destroy` | Allow destroying a non-empty bucket | `bool` | `false` |
| `kms_key_arn` | Customer-managed KMS key ARN. Uses the AWS-managed key when null | `string` | `null` |
| `tags` | Additional tags for the bucket | `map(string)` | `{}` |
| `versioning_enabled` | Keep previous object versions | `bool` | `true` |

## Outputs

| Name | Description |
|------|-------------|
| `bucket_arn` | ARN of the bucket |
| `bucket_name` | Name of the bucket |

## Tests

```bash
terraform test
```

The tests use a mocked AWS provider, so they need no cloud credentials.
