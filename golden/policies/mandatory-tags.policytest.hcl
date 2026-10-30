policytest {
  targets = ["mandatory-tags.policy.hcl"]
}

resource "aws_vpc" "tagged_via_default_tags" {
  attrs = {
    cidr_block = "10.0.0.0/16"
    tags_all = {
      owner               = "claims-platform@example.com"
      cost-center         = "CC-4711"
      data-classification = "confidential"
      environment         = "dev"
    }
  }
}

resource "aws_vpc" "legacy_name_tag_only" {
  expect_failure = true
  attrs = {
    cidr_block = "10.0.0.0/16"
    tags_all = {
      Name = "claims-vpc"
    }
  }
}

resource "aws_s3_bucket" "missing_classification" {
  expect_failure = true
  attrs = {
    bucket = "claims-portal-dev-claims-documents"
    tags_all = {
      owner       = "claims-platform@example.com"
      cost-center = "CC-4711"
    }
  }
}
