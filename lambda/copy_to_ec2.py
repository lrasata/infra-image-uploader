import boto3
import os

s3 = boto3.client('s3')
ssm = boto3.client('ssm')

SOURCE_BUCKET = os.environ['S3_BUCKET']
INSTANCE_ID = os.environ['EC2_INSTANCE_ID']

def handler(event, context):
    for record in event['Records']:
        key = record['s3']['object']['key']
        
        # Copy file to EC2 via SSM
        command = f"aws s3 cp s3://{SOURCE_BUCKET}/{key} /tmp/{key}"
        response = ssm.send_command(
            InstanceIds=[INSTANCE_ID],
            DocumentName="AWS-RunShellScript",
            Parameters={"commands":[command]}
        )
        print(f"File {key} sent to EC2 for scanning.")
