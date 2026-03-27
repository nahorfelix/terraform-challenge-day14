# Day 14 — Working with Multiple Providers (Part 1)

**Terraform 30-Day Challenge** · Chapter 7 · Multi-Region S3 Replication

---

## Overview

This project demonstrates how Terraform's provider system works under the hood — how providers are installed, versioned, and configured — and applies that knowledge by deploying real AWS infrastructure across two regions using **provider aliases**.

A primary S3 bucket is created in **us-east-1** (default provider) and a replica bucket in **us-west-2** (aliased provider), with cross-region replication (CRR) actively configured and verified between them.

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        AWS Account                              │
│                                                                 │
│   ┌──────────────────────┐        ┌──────────────────────┐     │
│   │      us-east-1        │        │      us-west-2        │     │
│   │                      │        │                      │     │
│   │  ┌────────────────┐  │  CRR   │  ┌────────────────┐  │     │
│   │  │  Primary Bucket │  │───────▶│  │ Replica Bucket │  │     │
│   │  │  (Versioning ✓) │  │        │  │ (Versioning ✓) │  │     │
│   │  └────────────────┘  │        │  └────────────────┘  │     │
│   │                      │        │                      │     │
│   │  provider "aws"       │        │  provider "aws"       │     │
│   │  (default)           │        │  alias = "us_west"   │     │
│   └──────────────────────┘        └──────────────────────┘     │
│                                                                 │
│   ┌────────────────────────────────────────────────────┐       │
│   │  IAM Replication Role + Policy (global)            │       │
│   └────────────────────────────────────────────────────┘       │
└─────────────────────────────────────────────────────────────────┘
```

---

## Resources Deployed

| Resource | Name | Region |
|---|---|---|
| `aws_s3_bucket` | `day14-multi-region-primary-*` | us-east-1 |
| `aws_s3_bucket_versioning` | primary | us-east-1 |
| `aws_s3_bucket_public_access_block` | primary | us-east-1 |
| `aws_s3_bucket` | `day14-multi-region-replica-*` | us-west-2 |
| `aws_s3_bucket_versioning` | replica | us-west-2 |
| `aws_s3_bucket_public_access_block` | replica | us-west-2 |
| `aws_s3_bucket_replication_configuration` | replicate-all | us-east-1 |
| `aws_iam_role` | `day14-multi-region-replication-role` | global |
| `aws_iam_policy` | `day14-multi-region-replication-policy` | global |
| `aws_iam_role_policy_attachment` | replication | global |

---

## File Structure

```
terraform-challenge-day14/
├── versions.tf                    # Terraform + provider version constraints
├── providers.tf                   # Default and aliased AWS provider configs
├── variables.tf                   # Input variables (regions, prefix, account ID)
├── main.tf                        # S3 buckets, versioning, replication config
├── iam.tf                         # IAM role and policy for S3 replication
├── outputs.tf                     # Bucket names, ARNs, regions, status
├── .terraform.lock.hcl            # Provider version lock file
├── .gitignore                     # Excludes .terraform/, *.tfstate, *.tfvars
└── DAY14-WORKSPACE-SUBMISSION.txt # Challenge workspace submission
```

---

## Prerequisites

| Tool | Minimum Version |
|---|---|
| Terraform | >= 1.0.0 |
| AWS CLI | any recent version |
| AWS credentials | configured via `aws configure` or environment variables |

The AWS identity used must have permissions to create S3 buckets, configure replication, and manage IAM roles and policies.

---

## Usage

### 1. Clone and initialize

```bash
git clone https://github.com/nahorfelix/terraform-challenge-day14.git
cd terraform-challenge-day14
terraform init
```

`terraform init` downloads the AWS provider (`hashicorp/aws v5.100.0`) and locks it in `.terraform.lock.hcl`.

### 2. Preview the plan

```bash
terraform plan
```

Expected: **10 resources to add, 0 to change, 0 to destroy.**

### 3. Deploy

```bash
terraform apply
```

Type `yes` when prompted, or use `-auto-approve` to skip confirmation.

### 4. Verify replication is live

```bash
# Upload a test object to the primary bucket
echo "replication test" | aws s3 cp - s3://<primary_bucket_name>/test.txt

# Check replication status on the source object
aws s3api head-object \
  --bucket <primary_bucket_name> \
  --key test.txt

# Confirm the replica exists in us-west-2
aws s3api head-object \
  --bucket <replica_bucket_name> \
  --key test.txt \
  --region us-west-2
```

The source object progresses: `PENDING` → `COMPLETED`. The destination object shows `ReplicationStatus: REPLICA`.

### 5. Destroy

```bash
terraform destroy
```

`force_destroy = true` is set on both buckets so they can be deleted even if they contain objects.

---

## Input Variables

| Variable | Default | Description |
|---|---|---|
| `primary_region` | `us-east-1` | Region for the source S3 bucket |
| `secondary_region` | `us-west-2` | Region for the replica S3 bucket |
| `bucket_prefix` | `day14-multi-region` | Prefix applied to both bucket names |
| `account_id` | `189979486358` | AWS account ID used in bucket naming |

To override any variable, create a `terraform.tfvars` file:

```hcl
bucket_prefix = "my-custom-prefix"
primary_region = "eu-west-1"
```

---

## Outputs

| Output | Description |
|---|---|
| `primary_bucket_name` | Name of the primary bucket |
| `primary_bucket_arn` | ARN of the primary bucket |
| `primary_bucket_region` | Region of the primary bucket |
| `replica_bucket_name` | Name of the replica bucket |
| `replica_bucket_arn` | ARN of the replica bucket |
| `replica_bucket_region` | Region of the replica bucket |
| `replication_role_arn` | ARN of the IAM replication role |
| `replication_status` | Human-readable replication summary |

---

## Key Concepts Demonstrated

**Provider Aliases** — Two `provider "aws"` blocks with the same type but different `alias` values target different AWS regions. Resources explicitly reference the aliased provider with `provider = aws.us_west`.

**Provider Version Locking** — The `~> 5.0` constraint in `versions.tf` allows minor updates but blocks major-version breaks. The `.terraform.lock.hcl` file pins the exact version (`5.100.0`) and stores SHA-256 hashes for all supported platforms to ensure reproducible and secure installs across all environments.

**Cross-Region Replication** — S3 CRR requires versioning enabled on both buckets and an IAM role that S3 can assume to read from the source and write to the destination. The `depends_on` meta-argument enforces that versioning is active before the replication configuration is applied.

**IAM for S3 Replication** — The replication role uses a trust policy that allows `s3.amazonaws.com` to assume it. The attached policy grants the minimum permissions needed: read from source, write to destination.

---

## Provider Version Lock File

```hcl
provider "registry.terraform.io/hashicorp/aws" {
  version     = "5.100.0"
  constraints = "~> 5.0"
  hashes = [
    "h1:H3mU/7URhP0uCRGK8jeQRKxx2XFzEqLiOq/L2Bbiaxs=",
    ...
  ]
}
```

This file is committed to version control so every team member and CI system installs the exact same provider binary.

---

## Challenge

**30-Day Terraform Challenge** — Day 14  
**Topic:** Working with Multiple Providers — Part 1  
**Source:** *Terraform: Up & Running* by Yevgeniy Brikman — Chapter 7
