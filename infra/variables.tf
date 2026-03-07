# ============================================================
# Variables
# ============================================================

variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "us-east-1"
}

variable "aws_profile" {
  description = "AWS CLI source profile for base credentials"
  type        = string
  default     = "default"
}

variable "assume_role_arn" {
  description = "IAM role ARN to assume (leave empty to skip AssumeRole)"
  type        = string
  default     = ""
}

variable "mfa_serial" {
  description = "MFA device ARN (leave empty if MFA not required)"
  type        = string
  default     = ""
}

variable "domain_name" {
  description = "Custom domain name (e.g., resume.example.com)"
  type        = string
}

variable "hosted_zone_id" {
  description = "Route 53 Hosted Zone ID for the domain"
  type        = string
}

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "cloud-resume"
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
  default     = "prod"
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    Project   = "cloud-resume-challenge"
    ManagedBy = "terraform"
  }
}
