# ============================================================
# Cloud Resume Challenge - Terraform Configuration
# ============================================================
# This configuration deploys:
#   - S3 bucket for static website hosting
#   - CloudFront distribution for CDN
#   - Route 53 DNS records for custom domain
#   - ACM SSL certificate
#   - DynamoDB table for visitor counter
#   - Lambda function for visitor counter API
#   - API Gateway for Lambda invocation
# ============================================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }

  backend "s3" {
    bucket       = "cloud-resume-state-992382750905"
    key          = "cloud-resume/terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = true
    encrypt      = true
    profile      = "KostasAdmin"
  }
}

# Primary provider - us-east-1 required for CloudFront + ACM
# NOTE: When using MFA, first run:
#   aws sts get-session-token --serial-number <mfa_arn> --token-code <code> --profile KostasAdmin
# Or simply export credentials via a wrapper script (see README).
#
# The simplest approach: generate temp creds and export them as env vars,
# then run terraform with profile = "KostasAdmin" and assume_role.
provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile != "" ? var.aws_profile : null

  dynamic "assume_role" {
    for_each = var.assume_role_arn != "" ? [1] : []
    content {
      role_arn = var.assume_role_arn
    }
  }
}
