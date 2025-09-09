import json
import boto3
import os
import uuid
import base64

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

def handler(event, context):
    """
    Lambda handler that generates a presigned S3 URL for upload.
    """

    headers = event.get("headers", {})
    custom_header = headers.get("x-custom-auth")

    # filename and ext from original request are transformed to queryStringParameters by API Gateway
    original_filename = event.get("queryStringParameters", {}).get("filename")
    extension = event.get("queryStringParameters", {}).get("ext")

    if custom_header != os.environ.get("CUSTOM_AUTH_SECRET"):
        return {
            "headers": corsHeaders,
            "statusCode": 403,
            "body": json.dumps({"error": "Forbidden: Invalid or missing custom auth header"})
        }
    
    try:
        # Generate a random unique filename
        random_id = base64.urlsafe_b64encode(uuid.uuid4().bytes).rstrip(b"=").decode("utf-8")
        file_key = f"{str(random_id)}_{original_filename}.{extension}"

        presigned_url = s3_client.generate_presigned_url(
            "put_object",
            Params={
                "Bucket": BUCKET_NAME,
                "Key": file_key
            },
            ExpiresIn=int(os.environ.get("EXPIRATION_TIME_S", 300))  # URL expiration time in seconds
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
