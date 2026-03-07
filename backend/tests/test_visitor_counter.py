import json
import os
import sys
import pytest
from unittest.mock import MagicMock, patch
from decimal import Decimal

# Set required env vars BEFORE any module import attempts
os.environ.setdefault("AWS_DEFAULT_REGION", "us-east-1")
os.environ.setdefault("TABLE_NAME", "test-visitor-counter")

# Add backend to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

# Import directly from the module file (using importlib to avoid 'lambda' keyword)
import importlib.util
_spec = importlib.util.spec_from_file_location(
    "visitor_counter",
    os.path.join(os.path.dirname(__file__), '..', 'lambda', 'visitor_counter.py')
)
vc = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(vc)


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
    """Create a mock API Gateway HTTP API v2 event with IP address."""
    return {
        "version": "2.0",
        "routeKey": "POST /visitor-count",
        "headers": {"content-type": "application/json"},
        "requestContext": {
            "http": {
                "method": "POST",
                "path": "/visitor-count",
                "sourceIp": "192.168.1.1",
            }
        },
        "body": None,
    }


def test_lambda_handler_new_visitor(apigw_event, lambda_context):
    """Test successful new visitor count increment."""
    mock_table = MagicMock()
    mock_table.get_item.return_value = {}
    mock_table.update_item.return_value = {
        "Attributes": {"visit_count": Decimal("1")}
    }

    with patch.object(vc, "table", mock_table):
        response = vc.lambda_handler(apigw_event, lambda_context)

    assert response["statusCode"] == 200
    body = json.loads(response["body"])
    assert body["visitor_count"] == 1
    assert body["is_new_visit"] is True
    assert "Access-Control-Allow-Origin" in response["headers"]


def test_lambda_handler_returning_visitor(apigw_event, lambda_context):
    """Test that returning visitor from same IP same day doesn't increment counter."""
    mock_table = MagicMock()
    # First get_item: check if IP visited today (yes)
    # Second get_item: get current visitor count
    mock_table.get_item.side_effect = [
        {"Item": {"id": "2026-03-07#192.168.1.1", "timestamp": "2026-03-07"}},
        {"Item": {"id": "visitor_count", "visit_count": Decimal("42")}},
    ]

    with patch.object(vc, "table", mock_table):
        response = vc.lambda_handler(apigw_event, lambda_context)

    assert response["statusCode"] == 200
    body = json.loads(response["body"])
    assert body["is_new_visit"] is False
    assert body["visitor_count"] == 42
    mock_table.update_item.assert_not_called()


def test_lambda_handler_error(apigw_event, lambda_context):
    """Test error handling when DynamoDB update fails."""
    mock_table = MagicMock()
    mock_table.get_item.return_value = {}  # First check succeeds
    mock_table.update_item.side_effect = Exception("DynamoDB error")  # But update fails

    with patch.object(vc, "table", mock_table):
        response = vc.lambda_handler(apigw_event, lambda_context)

    assert response["statusCode"] == 500
    body = json.loads(response["body"])
    assert "error" in body


def test_cors_headers_present(apigw_event, lambda_context):
    """Test that CORS headers are present in the response."""
    mock_table = MagicMock()
    mock_table.get_item.return_value = {}
    mock_table.update_item.return_value = {
        "Attributes": {"visit_count": Decimal("1")}
    }

    with patch.object(vc, "table", mock_table):
        response = vc.lambda_handler(apigw_event, lambda_context)

    headers = response["headers"]
    assert headers["Access-Control-Allow-Origin"] == "*"
    assert "Access-Control-Allow-Methods" in headers
    assert "Access-Control-Allow-Headers" in headers

