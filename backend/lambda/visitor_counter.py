import json
import boto3
import os
import logging
from datetime import datetime, timezone

logger = logging.getLogger()
logger.setLevel(logging.INFO)

dynamodb = boto3.resource("dynamodb")
table_name = os.environ.get("TABLE_NAME", "visitor-counter")
table = dynamodb.Table(table_name)


def lambda_handler(event, context):
    """
    Lambda function to track unique daily visitors by IP address.
    Only increments counter once per unique IP per day.
    Returns the total unique visitor count.
    """
    try:
        # Extract client IP from event
        client_ip = event.get("requestContext", {}).get("identity", {}).get("sourceIp", "unknown")
        
        # Get today's date in UTC
        today = datetime.now(timezone.utc).strftime("%Y-%m-%d")
        
        # Create unique key for today's visit from this IP
        visit_key = f"{today}#{client_ip}"
        
        logger.info(f"Processing visit from IP: {client_ip} on {today}")
        
        # Check if this IP has already visited today
        try:
            existing_visit = table.get_item(Key={"id": visit_key})
            
            if "Item" in existing_visit:
                # IP already visited today, don't increment
                logger.info(f"IP {client_ip} already visited today, not incrementing counter")
                # Get current total from counter
                counter_response = table.get_item(Key={"id": "visitor_count"})
                visitor_count = int(counter_response.get("Attributes", {}).get("visit_count", 0))
                
                return {
                    "statusCode": 200,
                    "headers": {
                        "Content-Type": "application/json",
                        "Access-Control-Allow-Origin": "*",
                        "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
                        "Access-Control-Allow-Headers": "Content-Type",
                    },
                    "body": json.dumps({"visitor_count": visitor_count, "is_new_visit": False}),
                }
        except Exception as e:
            logger.warning(f"Could not check existing visit: {str(e)}")
        
        # New unique visitor for today - record the visit and increment counter
        table.put_item(Item={"id": visit_key, "timestamp": today})
        
        # Increment the global counter
        response = table.update_item(
            Key={"id": "visitor_count"},
            UpdateExpression="ADD visit_count :inc",
            ExpressionAttributeValues={":inc": 1},
            ReturnValues="UPDATED_NEW",
        )

        visitor_count = int(response["Attributes"]["visit_count"])

        logger.info(f"New unique visitor recorded. Total count: {visitor_count}")

        return {
            "statusCode": 200,
            "headers": {
                "Content-Type": "application/json",
                "Access-Control-Allow-Origin": "*",
                "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
                "Access-Control-Allow-Headers": "Content-Type",
            },
            "body": json.dumps({"visitor_count": visitor_count, "is_new_visit": True}),
        }

    except Exception as e:
        logger.error(f"Error updating visitor count: {str(e)}")
        return {
            "statusCode": 500,
            "headers": {
                "Content-Type": "application/json",
                "Access-Control-Allow-Origin": "*",
            },
            "body": json.dumps({"error": "Could not update visitor count"}),
        }
