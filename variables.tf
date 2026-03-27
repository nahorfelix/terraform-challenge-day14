variable "primary_region" {
  description = "AWS primary region for the source S3 bucket"
  type        = string
  default     = "us-east-1"
}

variable "secondary_region" {
  description = "AWS secondary region for the replica S3 bucket"
  type        = string
  default     = "us-west-2"
}

variable "bucket_prefix" {
  description = "Prefix for both S3 bucket names (must be globally unique)"
  type        = string
  default     = "day14-multi-region"
}

variable "account_id" {
  description = "AWS account ID — used in IAM role ARNs"
  type        = string
  default     = "189979486358"
}
