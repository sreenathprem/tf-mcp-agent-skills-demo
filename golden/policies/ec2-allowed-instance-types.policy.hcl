# Converted from sentinel/restrict-ec2-instance-type.sentinel
# Conversion quality: Perfect
#
# - Sentinel `param allowed_types`       -> `input "allowed_types"` (overridable per policy set)
# - Sentinel filter on create/update      -> `operations = ["create", "update"]`
# - Sentinel `print(address, ...)` output -> remediation-focused error_message
#   (Terraform Policy diagnostics already identify the failing resource)

policy {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0, < 7.0.0"
    }
  }
}

input "allowed_types" {
  type    = list(string)
  default = ["t3.micro", "t3.small", "t3.medium", "t3.large", "m6i.large"]
}

resource_policy "aws_instance" "allowed_instance_types" {
  operations = ["create", "update"]

  locals {
    # core::try() only catches errors, not null values
    instance_type = core::try(attrs.instance_type, null) == null ? "" : attrs.instance_type
  }

  enforce {
    condition     = core::contains(input.allowed_types, local.instance_type)
    error_message = "EC2 instance type '${local.instance_type}' is not approved. Use one of: ${core::join(", ", input.allowed_types)}."
  }
}
