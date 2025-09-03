import json
import boto3
import os
import uuid

s3_client = boto3.client("s3", 
                         region_name=os.environ.get("REGION", "eu-central-1"),
                         endpoint_url=f"https://s3.{os.environ.get('REGION','eu-central-1')}.amazonaws.com")

# Read bucket name from environment variable
BUCKET_NAME = os.environ.get("UPLOAD_BUCKET", "s3-bucket-name")

corsHeaders = {
    "Content-Type": "application/json",
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers": "Content-Type",
    "Access-Control-Allow-Methods": "GET,OPTIONS,PUT",
}

def lambda_handler(event, context):
    """
    Lambda handler that generates a presigned S3 URL for upload.
    """

    headers = event.get("headers", {})
    custom_header = headers.get("x-custom-auth")

    if custom_header != os.environ.get("CUSTOM_AUTH_SECRET"):
        return {
            "headers": corsHeaders,
            "statusCode": 403,
            "body": json.dumps({"error": "Forbidden: Invalid or missing custom auth header"})
        }
    
    try:
        # Generate a random unique filename (you can also prefix with user ID or folder)
        file_key = str(uuid.uuid4())

        presigned_url = s3_client.generate_presigned_url(
            "put_object",
            Params={
                "Bucket": BUCKET_NAME,
                "Key": file_key
            },
            ExpiresIn=3600  # URL valid for 1 hour
        )

        return {
            "statusCode": 200,
            "headers": corsHeaders,
            "body": json.dumps({
                "upload_url": presigned_url,
                "file_key": file_key
            })
        }

    except Exception as e:
        return {
            "headers": corsHeaders,
            "statusCode": 500,
            "body": json.dumps({"error": str(e)})
        }
