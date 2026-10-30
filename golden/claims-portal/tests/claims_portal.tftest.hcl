# Integration tests for the claims-portal root configuration.
# The AWS provider is mocked, so the approved private-registry modules are
# exercised end to end without credentials or real infrastructure.

mock_provider "aws" {
  # The vpc module indexes availability zone names by subnet, so the mock
  # must return real-looking zones.
  mock_data "aws_availability_zones" {
    defaults = {
      names = ["eu-central-1a", "eu-central-1b", "eu-central-1c"]
    }
  }

  mock_data "aws_ssm_parameter" {
    defaults = {
      insecure_value = "ami-0123456789abcdef0"
    }
  }

  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }
}

variables {
  environment = "dev"
  owner       = "claims-platform@example.com"
  cost_center = "CC-4711"
}

run "plans_with_defaults" {
  command = plan

  assert {
    condition     = output.documents_bucket_name == "claims-portal-dev-claims-documents"
    error_message = "Documents bucket must follow the <application>-<environment>-claims-documents naming convention."
  }
}

run "applies_mandatory_tags" {
  command = plan

  assert {
    condition = alltrue([
      for key in ["application", "environment", "owner", "cost-center", "data-classification", "managed-by"] :
      contains(keys(local.common_tags), key)
    ])
    error_message = "All mandatory tags must be applied through provider default_tags."
  }

  assert {
    condition     = local.common_tags["data-classification"] == "confidential"
    error_message = "Claim documents must be classified as confidential by default."
  }
}

run "rejects_unknown_environment" {
  command = plan

  variables {
    environment = "staging"
  }

  expect_failures = [var.environment]
}

run "rejects_unapproved_instance_type" {
  command = plan

  variables {
    instance_type = "m5.2xlarge"
  }

  expect_failures = [var.instance_type]
}

run "rejects_more_nodes_than_subnets" {
  command = plan

  variables {
    node_count = 3
  }

  expect_failures = [var.node_count]
}

run "rejects_invalid_cost_center" {
  command = plan

  variables {
    cost_center = "marketing"
  }

  expect_failures = [var.cost_center]
}
