# Default provider — primary region (us-east-1)
provider "aws" {
  region = var.primary_region
}

# Aliased provider — secondary region (us-west-2)
provider "aws" {
  alias  = "us_west"
  region = var.secondary_region
}
