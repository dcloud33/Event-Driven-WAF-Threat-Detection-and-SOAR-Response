import json
import boto3
import uuid
from datetime import datetime

dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table("token-tracking")

def lambda_handler(event, context):
    claims = event.get("requestContext", {}).get("authorizer", {}).get("claims", {})
    groups = claims.get("cognito:groups", [])

    path = event.get("resource")
    token_id = str(uuid.uuid4())

    # RBAC logic
    if path == "/node" and "admins" not in groups:
        return {
            "statusCode": 403,
            "body": json.dumps({"error": "Access denied"})
        }
    table.update_item(
    Key={"token_id": token_id},
    UpdateExpression="SET used = :u",
    ExpressionAttributeValues={
        ":u": True
    }
    
)   

    return {
        "statusCode": 200,
        "body": json.dumps({
            "message": "Access granted",
            "groups": groups
        })
    }

    






