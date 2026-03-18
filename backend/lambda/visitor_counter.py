import json
import boto3
import os
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

dynamodb = boto3.resource("dynamodb")
table_name = os.environ.get("TABLE_NAME", "visitor-counter")
table = dynamodb.Table(table_name)
allowed_origin = os.environ.get("ALLOWED_ORIGIN", "")


def lambda_handler(event, context):
    """
    Lambda function to track and return website visitor count.
    Increments the counter in DynamoDB and returns the updated count.
    """
    try:
        # Atomic counter increment
        response = table.update_item(
            Key={"id": "visitor_count"},
            UpdateExpression="ADD visit_count :inc",
            ExpressionAttributeValues={":inc": 1},
            ReturnValues="UPDATED_NEW",
        )

        visitor_count = int(response["Attributes"]["visit_count"])

        logger.info(f"Visitor count updated to: {visitor_count}")

        return {
            "statusCode": 200,
            "headers": {
                "Content-Type": "application/json",
                "Access-Control-Allow-Origin": allowed_origin,
                "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
                "Access-Control-Allow-Headers": "Content-Type",
            },
            "body": json.dumps({"visitor_count": visitor_count}),
        }

    except Exception as e:
        logger.error(f"Error updating visitor count: {str(e)}")
        return {
            "statusCode": 500,
            "headers": {
                "Content-Type": "application/json",
                "Access-Control-Allow-Origin": allowed_origin,
            },
            "body": json.dumps({"error": "Could not update visitor count"}),
        }
