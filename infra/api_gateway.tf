# ============================================================
# API Gateway v2 (HTTP API) - Visitor Counter Endpoint
# ============================================================

resource "aws_apigatewayv2_api" "visitor_api" {
  name          = "${var.project_name}-visitor-api"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = ["https://${var.domain_name}"]
    allow_methods = ["GET", "POST", "OPTIONS"]
    allow_headers = ["Content-Type"]
    max_age       = 86400
  }

  tags = var.tags
}

# Lambda integration
resource "aws_apigatewayv2_integration" "visitor_counter" {
  api_id                 = aws_apigatewayv2_api.visitor_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.visitor_counter.invoke_arn
  integration_method     = "POST"
  payload_format_version = "2.0"
}

# Route: POST /visitor-count
resource "aws_apigatewayv2_route" "visitor_count" {
  api_id    = aws_apigatewayv2_api.visitor_api.id
  route_key = "POST /visitor-count"
  target    = "integrations/${aws_apigatewayv2_integration.visitor_counter.id}"
}

# Deploy stage
resource "aws_apigatewayv2_stage" "api" {
  api_id      = aws_apigatewayv2_api.visitor_api.id
  name        = var.environment
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_logs.arn
    format = jsonencode({
      requestId      = "$context.requestId"
      ip             = "$context.identity.sourceIp"
      requestTime    = "$context.requestTime"
      httpMethod     = "$context.httpMethod"
      routeKey       = "$context.routeKey"
      status         = "$context.status"
      protocol       = "$context.protocol"
      responseLength = "$context.responseLength"
    })
  }

  tags = var.tags
}

# Permission for API Gateway to invoke Lambda
resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.visitor_counter.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.visitor_api.execution_arn}/*/*"
}

# CloudWatch Log Group for API Gateway
resource "aws_cloudwatch_log_group" "api_logs" {
  name              = "/aws/apigateway/${var.project_name}-visitor-api"
  retention_in_days = 14

  tags = var.tags
}
