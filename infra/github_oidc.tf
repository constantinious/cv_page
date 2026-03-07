# ============================================================
# GitHub Actions OIDC - IAM Role for CI/CD
# ============================================================
# Uses the existing GitHub OIDC provider in the account.
# Grants least-privilege permissions for:
#   - Frontend: S3 sync + CloudFront invalidation
#   - Backend:  Lambda function update
#   - Terraform: Full infra management via CI/CD
# ============================================================

# Reference the existing OIDC provider (already created in account)
data "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
}

# IAM Role trusted by GitHub Actions for this repo
resource "aws_iam_role" "github_actions" {
  name = "${var.project_name}-github-actions"
  path = "/"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = data.aws_iam_openid_connect_provider.github.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:${var.github_repo}:*"
          }
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Name = "${var.project_name}-github-actions"
  })
}

# -------------------------------------------------------
# Policy: Frontend deployment (S3 + CloudFront)
# -------------------------------------------------------
resource "aws_iam_role_policy" "frontend_deploy" {
  name = "${var.project_name}-frontend-deploy"
  role = aws_iam_role.github_actions.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "S3Sync"
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.website.arn,
          "${aws_s3_bucket.website.arn}/*"
        ]
      },
      {
        Sid    = "CloudFrontInvalidation"
        Effect = "Allow"
        Action = [
          "cloudfront:CreateInvalidation",
          "cloudfront:GetInvalidation",
          "cloudfront:ListInvalidations"
        ]
        Resource = aws_cloudfront_distribution.website.arn
      }
    ]
  })
}

# -------------------------------------------------------
# Policy: Backend deployment (Lambda)
# -------------------------------------------------------
resource "aws_iam_role_policy" "backend_deploy" {
  name = "${var.project_name}-backend-deploy"
  role = aws_iam_role.github_actions.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "LambdaDeploy"
        Effect = "Allow"
        Action = [
          "lambda:UpdateFunctionCode",
          "lambda:GetFunction",
          "lambda:GetFunctionConfiguration"
        ]
        Resource = aws_lambda_function.visitor_counter.arn
      }
    ]
  })
}

# -------------------------------------------------------
# Policy: Terraform state access (S3 backend)
# -------------------------------------------------------
resource "aws_iam_role_policy" "terraform_state" {
  name = "${var.project_name}-terraform-state"
  role = aws_iam_role.github_actions.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "StateBucketAccess"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::cloud-resume-state-992382750905",
          "arn:aws:s3:::cloud-resume-state-992382750905/*"
        ]
      }
    ]
  })
}

# -------------------------------------------------------
# Policy: Terraform infrastructure management
# -------------------------------------------------------
resource "aws_iam_role_policy" "terraform_infra" {
  name = "${var.project_name}-terraform-infra"
  role = aws_iam_role.github_actions.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "S3Management"
        Effect = "Allow"
        Action = [
          "s3:CreateBucket",
          "s3:DeleteBucket",
          "s3:Get*",
          "s3:Put*",
          "s3:List*"
        ]
        Resource = [
          aws_s3_bucket.website.arn,
          "${aws_s3_bucket.website.arn}/*"
        ]
      },
      {
        Sid    = "CloudFrontManagement"
        Effect = "Allow"
        Action = [
          "cloudfront:*"
        ]
        Resource = "*"
      },
      {
        Sid    = "ACMManagement"
        Effect = "Allow"
        Action = [
          "acm:DescribeCertificate",
          "acm:ListCertificates",
          "acm:GetCertificate",
          "acm:ListTagsForCertificate",
          "acm:RequestCertificate",
          "acm:DeleteCertificate",
          "acm:AddTagsToCertificate"
        ]
        Resource = "*"
      },
      {
        Sid    = "Route53Management"
        Effect = "Allow"
        Action = [
          "route53:GetHostedZone",
          "route53:ChangeResourceRecordSets",
          "route53:GetChange",
          "route53:ListResourceRecordSets",
          "route53:ListTagsForResource"
        ]
        Resource = [
          "arn:aws:route53:::hostedzone/${var.hosted_zone_id}",
          "arn:aws:route53:::change/*"
        ]
      },
      {
        Sid    = "DynamoDBManagement"
        Effect = "Allow"
        Action = [
          "dynamodb:CreateTable",
          "dynamodb:DeleteTable",
          "dynamodb:DescribeTable",
          "dynamodb:DescribeContinuousBackups",
          "dynamodb:DescribeTimeToLive",
          "dynamodb:ListTagsOfResource",
          "dynamodb:TagResource",
          "dynamodb:UntagResource",
          "dynamodb:UpdateTable",
          "dynamodb:UpdateContinuousBackups",
          "dynamodb:UpdateTimeToLive"
        ]
        Resource = aws_dynamodb_table.visitor_counter.arn
      },
      {
        Sid    = "LambdaManagement"
        Effect = "Allow"
        Action = [
          "lambda:*"
        ]
        Resource = [
          aws_lambda_function.visitor_counter.arn,
          "${aws_lambda_function.visitor_counter.arn}:*"
        ]
      },
      {
        Sid    = "IAMRoleManagement"
        Effect = "Allow"
        Action = [
          "iam:GetRole",
          "iam:GetRolePolicy",
          "iam:CreateRole",
          "iam:DeleteRole",
          "iam:PutRolePolicy",
          "iam:DeleteRolePolicy",
          "iam:AttachRolePolicy",
          "iam:DetachRolePolicy",
          "iam:ListRolePolicies",
          "iam:ListAttachedRolePolicies",
          "iam:ListInstanceProfilesForRole",
          "iam:PassRole",
          "iam:TagRole",
          "iam:UntagRole"
        ]
        Resource = [
          aws_iam_role.lambda_role.arn,
          aws_iam_role.github_actions.arn
        ]
      },
      {
        Sid    = "IAMOIDCRead"
        Effect = "Allow"
        Action = [
          "iam:GetOpenIDConnectProvider"
        ]
        Resource = data.aws_iam_openid_connect_provider.github.arn
      },
      {
        Sid    = "APIGatewayManagement"
        Effect = "Allow"
        Action = [
          "apigateway:*"
        ]
        Resource = [
          "arn:aws:apigateway:${var.aws_region}::/apis/*",
          "arn:aws:apigateway:${var.aws_region}::/apis"
        ]
      },
      {
        Sid    = "CloudWatchLogs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:DeleteLogGroup",
          "logs:DescribeLogGroups",
          "logs:ListTagsForResource",
          "logs:PutRetentionPolicy",
          "logs:TagResource",
          "logs:UntagResource"
        ]
        Resource = "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${var.project_name}-*"
      },
      {
        Sid    = "STSGetCaller"
        Effect = "Allow"
        Action = [
          "sts:GetCallerIdentity"
        ]
        Resource = "*"
      }
    ]
  })
}

# -------------------------------------------------------
# Output: Role ARN (needed for GitHub secret)
# -------------------------------------------------------
output "github_actions_role_arn" {
  description = "IAM Role ARN for GitHub Actions OIDC authentication"
  value       = aws_iam_role.github_actions.arn
}
