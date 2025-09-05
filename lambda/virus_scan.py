import boto3, os, subprocess

s3 = boto3.client("s3")

# Path to clamscan in your Lambda layer
CLAMSCAN_PATH = "/opt/bin/clamscan"

def virus_scan_handler(event, context):
    # Detect event source format
    if "Records" in event:  
        # Classic S3 event notification
        record = event["Records"][0]["s3"]
        bucket = record["bucket"]["name"]
        key = record["object"]["key"]
    elif "detail" in event and "bucket" in event["detail"]:  
        # EventBridge S3 event
        bucket = event["detail"]["bucket"]["name"]
        key = event["detail"]["object"]["key"]
    else:
        raise ValueError("Unsupported event format")

    download_path = f"/tmp/{os.path.basename(key)}"
    s3.download_file(bucket, key, download_path)

    # Run ClamAV from Lambda layer
    result = subprocess.run([CLAMSCAN_PATH, download_path], capture_output=True, text=True)

    if "Infected files: 0" in result.stdout:
        print(f"{key} is clean ✅")
    else:
        print(f"{key} is INFECTED 🚨 moving file to quarantine bucket...")
        s3.copy_object(
            Bucket=os.environ["QUARANTINE_BUCKET"],
            CopySource={"Bucket": bucket, "Key": key},
            Key=key
        )
        s3.delete_object(Bucket=bucket, Key=key)