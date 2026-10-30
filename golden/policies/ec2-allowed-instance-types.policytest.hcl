policytest {
  targets = ["ec2-allowed-instance-types.policy.hcl"]
}

resource "aws_instance" "approved_type" {
  attrs = {
    instance_type = "t3.medium"
  }
}

resource "aws_instance" "legacy_oversized_type" {
  expect_failure = true
  attrs = {
    instance_type = "m5.2xlarge"
  }
}

resource "aws_instance" "unset_type" {
  expect_failure = true
  attrs = {
    instance_type = null
  }
}
