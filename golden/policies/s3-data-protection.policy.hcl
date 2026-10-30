# Claim documents are confidential: S3 buckets must block public access and
# encrypt with KMS.
#
# NOTE: The aws_s3_bucket check looks up companion resources by bucket name.
# For a bucket created in the same run, the companion's bucket argument is
# only known after the bucket exists, so that check fully resolves at apply
# time. The companion resource checks below run at plan time.

policy {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0, < 7.0.0"
    }
  }
}

resource_policy "aws_s3_bucket" "requires_protection" {
  locals {
    bucket_name = core::try(attrs.bucket, "")

    public_access_blocks = core::getresources("aws_s3_bucket_public_access_block", { bucket = local.bucket_name })
    encryption_configs   = core::getresources("aws_s3_bucket_server_side_encryption_configuration", { bucket = local.bucket_name })
  }

  enforce {
    condition     = core::length(local.public_access_blocks) > 0
    error_message = "S3 bucket '${local.bucket_name}' has no aws_s3_bucket_public_access_block. Add one with all four settings enabled."
  }

  enforce {
    condition     = core::length(local.encryption_configs) > 0
    error_message = "S3 bucket '${local.bucket_name}' has no aws_s3_bucket_server_side_encryption_configuration. Add one that uses aws:kms."
  }
}

resource_policy "aws_s3_bucket_public_access_block" "all_settings_enabled" {
  locals {
    settings = [
      core::try(attrs.block_public_acls, false),
      core::try(attrs.block_public_policy, false),
      core::try(attrs.ignore_public_acls, false),
      core::try(attrs.restrict_public_buckets, false),
    ]
  }

  enforce {
    condition     = core::alltrue(local.settings)
    error_message = "S3 public access block must enable block_public_acls, block_public_policy, ignore_public_acls and restrict_public_buckets."
  }
}

resource_policy "aws_s3_bucket_server_side_encryption_configuration" "kms_encryption" {
  locals {
    algorithms = [
      for rule in core::try(attrs.rule, []) :
      core::try(rule.apply_server_side_encryption_by_default[0].sse_algorithm, "")
    ]
    kms_algorithms = ["aws:kms", "aws:kms:dsse"]
    non_kms        = [for algorithm in local.algorithms : algorithm if !core::contains(local.kms_algorithms, algorithm)]
  }

  enforce {
    condition     = core::length(local.algorithms) > 0 && core::length(local.non_kms) == 0
    error_message = "S3 default encryption must use aws:kms or aws:kms:dsse."
  }
}
