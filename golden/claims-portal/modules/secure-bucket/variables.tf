variable "bucket_name" {
  description = "Globally unique name of the S3 bucket."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$", var.bucket_name))
    error_message = "Bucket name must be 3-63 characters of lowercase letters, numbers, dots, or hyphens, and must start and end with a letter or number."
  }
}

variable "force_destroy" {
  description = "Allow the bucket to be destroyed even when it still contains objects."
  type        = bool
  default     = false
}

variable "kms_key_arn" {
  description = "Customer-managed KMS key ARN used for default encryption. Uses the AWS-managed S3 key when null."
  type        = string
  default     = null

  validation {
    condition     = var.kms_key_arn == null || can(regex("^arn:aws[a-z-]*:kms:", var.kms_key_arn))
    error_message = "KMS key must be a KMS key ARN."
  }
}

variable "tags" {
  description = "Additional tags for the bucket. Provider default_tags are applied as well."
  type        = map(string)
  default     = {}
}

variable "versioning_enabled" {
  description = "Keep previous versions of objects so that overwritten or deleted files can be recovered."
  type        = bool
  default     = true
}
