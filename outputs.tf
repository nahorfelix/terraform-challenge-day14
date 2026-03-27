output "primary_bucket_name" {
  description = "Name of the primary S3 bucket in us-east-1"
  value       = aws_s3_bucket.primary.id
}

output "primary_bucket_arn" {
  description = "ARN of the primary S3 bucket"
  value       = aws_s3_bucket.primary.arn
}

output "primary_bucket_region" {
  description = "Region of the primary bucket"
  value       = aws_s3_bucket.primary.region
}

output "replica_bucket_name" {
  description = "Name of the replica S3 bucket in us-west-2"
  value       = aws_s3_bucket.replica.id
}

output "replica_bucket_arn" {
  description = "ARN of the replica S3 bucket"
  value       = aws_s3_bucket.replica.arn
}

output "replica_bucket_region" {
  description = "Region of the replica bucket"
  value       = aws_s3_bucket.replica.region
}

output "replication_role_arn" {
  description = "ARN of the IAM role used for S3 replication"
  value       = aws_iam_role.replication.arn
}

output "replication_status" {
  description = "Summary of the multi-region replication setup"
  value       = "Replication active: ${aws_s3_bucket.primary.id} (${var.primary_region}) → ${aws_s3_bucket.replica.id} (${var.secondary_region})"
}
