variable "application" {
  description = "Application name, used as a prefix for resource names."
  type        = string
  default     = "claims-portal"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,20}$", var.application))
    error_message = "Application must be 3-21 lowercase alphanumeric characters or hyphens, starting with a letter."
  }
}

variable "cost_center" {
  description = "Cost center that is charged for this stack."
  type        = string

  validation {
    condition     = can(regex("^CC-[0-9]{4}$", var.cost_center))
    error_message = "Cost center must match the format CC-1234."
  }
}

variable "data_classification" {
  description = "Highest classification of data stored by this stack."
  type        = string
  default     = "confidential"

  validation {
    condition     = contains(["public", "internal", "confidential", "restricted"], var.data_classification)
    error_message = "Data classification must be public, internal, confidential, or restricted."
  }
}

variable "documents_kms_key_arn" {
  description = "Customer-managed KMS key ARN for the claim documents bucket. Uses the AWS-managed S3 key when null."
  type        = string
  default     = null
}

variable "environment" {
  description = "Deployment environment."
  type        = string

  validation {
    condition     = contains(["dev", "test", "prod"], var.environment)
    error_message = "Environment must be dev, test, or prod."
  }
}

variable "instance_type" {
  description = "EC2 instance type for the ECS container hosts."
  type        = string
  default     = "t3.medium"

  validation {
    condition     = contains(["t3.micro", "t3.small", "t3.medium", "t3.large", "m6i.large"], var.instance_type)
    error_message = "Instance type must be on the platform-approved list: t3.micro, t3.small, t3.medium, t3.large, m6i.large."
  }
}

variable "nginx_replicas" {
  description = "Number of nginx tasks to run on the cluster."
  type        = number
  default     = 2

  validation {
    condition     = var.nginx_replicas >= 1 && var.nginx_replicas <= 10
    error_message = "Nginx replicas must be between 1 and 10."
  }
}

variable "node_count" {
  description = "Number of ECS container hosts. The approved ecs-cluster module places one host per public subnet and registers two hosts with the load balancer."
  type        = number
  default     = 2

  validation {
    condition     = var.node_count >= 2 && var.node_count <= length(var.public_subnet_cidrs)
    error_message = "Node count must be at least 2 and no more than the number of public subnets."
  }
}

variable "owner" {
  description = "Team or individual accountable for this stack (email address)."
  type        = string

  validation {
    condition     = can(regex("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$", var.owner))
    error_message = "Owner must be an email address."
  }
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for the public subnets, one per availability zone."
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]

  validation {
    condition     = length(var.public_subnet_cidrs) >= 2 && alltrue([for cidr in var.public_subnet_cidrs : can(cidrhost(cidr, 0))])
    error_message = "Provide at least two valid public subnet CIDR blocks."
  }
}

variable "region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "eu-central-1"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid IPv4 CIDR block."
  }
}
