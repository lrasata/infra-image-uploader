import json
import boto3
import os
import uuid

s3_client = boto3.client("s3")

# Read bucket name from environment variable
BUCKET_NAME = os.environ.get("UPLOAD_BUCKET", "s3-bucket-name")

def lambda_handler(event, context):
    """
    Lambda handler that generates a presigned S3 URL for upload.
    """
    try:
        # Generate a random unique filename (you can also prefix with user ID or folder)
        file_key = str(uuid.uuid4())

        # Default to generic binary content type
        file_type = "image/*"

        presigned_url = s3_client.generate_presigned_url(
            "put_object",
            Params={
                "Bucket": BUCKET_NAME,
                "Key": file_key,
                "ContentType": file_type
            },
            ExpiresIn=3600  # URL valid for 1 hour
        )

        return {
            "statusCode": 200,
            "headers": {
                "Access-Control-Allow-Origin": "*",
                "Access-Control-Allow-Methods": "GET,PUT,OPTIONS",
                "Access-Control-Allow-Headers": "Content-Type"
            },
            "body": json.dumps({
                "upload_url": presigned_url,
                "file_key": file_key
            })
        }

    except Exception as e:
        return {
            "statusCode": 500,
            "body": json.dumps({"error": str(e)})
        }
