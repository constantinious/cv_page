import json
import os
import pytest
from unittest.mock import MagicMock, patch
from decimal import Decimal


@pytest.fixture
def lambda_context():
    """Create a mock Lambda context."""
    context = MagicMock()
    context.function_name = "visitor-counter"
    context.memory_limit_in_mb = 128
    context.invoked_function_arn = "arn:aws:lambda:us-east-1:123456789:function:visitor-counter"
    return context


@pytest.fixture
def apigw_event():
    """Create a mock API Gateway event."""
    return {
        "httpMethod": "POST",
        "path": "/visitor-count",
        "headers": {"Content-Type": "application/json"},
        "body": None,
    }


@patch.dict(os.environ, {"TABLE_NAME": "test-visitor-counter"})
@patch("backend.lambda.visitor_counter.dynamodb")
def test_lambda_handler_success(mock_dynamodb, apigw_event, lambda_context):
    """Test successful visitor count increment."""
    mock_table = MagicMock()
    mock_table.update_item.return_value = {
        "Attributes": {"visit_count": Decimal("42")}
    }
    mock_dynamodb.Table.return_value = mock_table

    # Re-import to pick up mocked env
    from backend.lambda.visitor_counter import lambda_handler

    with patch("backend.lambda.visitor_counter.table", mock_table):
        response = lambda_handler(apigw_event, lambda_context)

    assert response["statusCode"] == 200
    body = json.loads(response["body"])
    assert body["visitor_count"] == 42
    assert "Access-Control-Allow-Origin" in response["headers"]


@patch.dict(os.environ, {"TABLE_NAME": "test-visitor-counter"})
@patch("backend.lambda.visitor_counter.dynamodb")
def test_lambda_handler_error(mock_dynamodb, apigw_event, lambda_context):
    """Test error handling when DynamoDB fails."""
    mock_table = MagicMock()
    mock_table.update_item.side_effect = Exception("DynamoDB error")
    mock_dynamodb.Table.return_value = mock_table

    from backend.lambda.visitor_counter import lambda_handler

    with patch("backend.lambda.visitor_counter.table", mock_table):
        response = lambda_handler(apigw_event, lambda_context)

    assert response["statusCode"] == 500
    body = json.loads(response["body"])
    assert "error" in body


@patch.dict(os.environ, {"TABLE_NAME": "test-visitor-counter"})
@patch("backend.lambda.visitor_counter.dynamodb")
def test_cors_headers_present(mock_dynamodb, apigw_event, lambda_context):
    """Test that CORS headers are present in the response."""
    mock_table = MagicMock()
    mock_table.update_item.return_value = {
        "Attributes": {"visit_count": Decimal("1")}
    }
    mock_dynamodb.Table.return_value = mock_table

    from backend.lambda.visitor_counter import lambda_handler

    with patch("backend.lambda.visitor_counter.table", mock_table):
        response = lambda_handler(apigw_event, lambda_context)

    headers = response["headers"]
    assert headers["Access-Control-Allow-Origin"] == "*"
    assert "Access-Control-Allow-Methods" in headers
    assert "Access-Control-Allow-Headers" in headers
