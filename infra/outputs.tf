# ============================================================
# Outputs
# ============================================================

output "website_url" {
  description = "CloudFront distribution URL"
  value       = "https://${aws_cloudfront_distribution.website.domain_name}"
}

output "custom_domain_url" {
  description = "Custom domain URL"
  value       = "https://${var.domain_name}"
}

output "s3_bucket_name" {
  description = "S3 bucket name for frontend deployment"
  value       = aws_s3_bucket.website.id
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID (for cache invalidation)"
  value       = aws_cloudfront_distribution.website.id
}

output "api_endpoint" {
  description = "API Gateway endpoint URL for visitor counter"
  value       = "${aws_apigatewayv2_stage.api.invoke_url}/visitor-count"
}

output "dynamodb_table_name" {
  description = "DynamoDB table name"
  value       = aws_dynamodb_table.visitor_counter.name
}

output "lambda_function_name" {
  description = "Lambda function name"
  value       = aws_lambda_function.visitor_counter.function_name
}

output "acm_certificate_arn" {
  description = "ACM certificate ARN"
  value       = aws_acm_certificate.cert.arn
}
