# ─────────────────────────────────────────────────
# PRIMARY BUCKET  —  us-east-1  (default provider)
# ─────────────────────────────────────────────────
resource "aws_s3_bucket" "primary" {
  bucket        = "${var.bucket_prefix}-primary-${var.account_id}"
  force_destroy = true

  tags = {
    Name        = "Day14 Primary Bucket"
    Region      = var.primary_region
    Challenge   = "day14-multi-provider"
  }
}

# Versioning is required for S3 replication
resource "aws_s3_bucket_versioning" "primary" {
  bucket = aws_s3_bucket.primary.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Block all public access on primary bucket
resource "aws_s3_bucket_public_access_block" "primary" {
  bucket = aws_s3_bucket.primary.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ─────────────────────────────────────────────────
# REPLICA BUCKET  —  us-west-2  (aliased provider)
# ─────────────────────────────────────────────────
resource "aws_s3_bucket" "replica" {
  provider      = aws.us_west
  bucket        = "${var.bucket_prefix}-replica-${var.account_id}"
  force_destroy = true

  tags = {
    Name        = "Day14 Replica Bucket"
    Region      = var.secondary_region
    Challenge   = "day14-multi-provider"
  }
}

# Versioning must be enabled on the destination bucket too
resource "aws_s3_bucket_versioning" "replica" {
  provider = aws.us_west
  bucket   = aws_s3_bucket.replica.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Block all public access on replica bucket
resource "aws_s3_bucket_public_access_block" "replica" {
  provider = aws.us_west
  bucket   = aws_s3_bucket.replica.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ─────────────────────────────────────────────────
# REPLICATION CONFIGURATION  —  primary → replica
# ─────────────────────────────────────────────────
resource "aws_s3_bucket_replication_configuration" "replication" {
  # Must wait for versioning to be active before configuring replication
  depends_on = [
    aws_s3_bucket_versioning.primary,
    aws_s3_bucket_versioning.replica
  ]

  role   = aws_iam_role.replication.arn
  bucket = aws_s3_bucket.primary.id

  rule {
    id     = "replicate-all"
    status = "Enabled"

    destination {
      bucket        = aws_s3_bucket.replica.arn
      storage_class = "STANDARD"
    }
  }
}
