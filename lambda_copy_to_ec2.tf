
resource "aws_iam_role" "lambda_copy_to_ec2_exec_role" {
  name = "${var.environment}-lambda-copy-to-ec2-exec-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_lambda_function" "copy_to_ec2" {
  function_name = "${var.environment}-s3-to-ec2-copy-lambda"
  runtime       = "python3.11"
  handler       = "copy_to_ec2.handler"

  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  role = aws_iam_role.lambda_copy_to_ec2_exec_role.arn

  environment {
    variables = {
      EC2_INSTANCE_ID = aws_instance.scanner_ec2_instance.id
      S3_BUCKET       = aws_s3_bucket.s3_bucket_uploads.bucket
    }
  }
}

# IAM Policy for S3 access
resource "aws_iam_policy" "s3_access_policy" {
  name        = "${var.environment}-lambda_copy_to_ec2_s3_access_policy"
  description = "Allow Lambda to access S3 upload bucket for read"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = ["s3:GetObject", "s3:GetObjectVersion", "s3:ListBucket"]
        Effect = "Allow"
        Resource = [
          "${aws_s3_bucket.s3_bucket_uploads.arn}/*",
          "${aws_s3_bucket.s3_bucket_uploads.arn}"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_copy_to_ec2_s3_access_policy" {
  role       = aws_iam_role.lambda_copy_to_ec2_exec_role.name
  policy_arn = aws_iam_policy.s3_access_policy.arn
}

# The Lambda function cannot SSH directly into EC2 instances (and SSH keys in Lambda are tricky).
# Using SSM Agent on EC2, the Lambda can:
# - Copy files to /tmp on EC2.
# - Execute shell commands.
# - Trigger processing or scanning by Inspector2.
resource "aws_iam_policy" "lambda_ssm_policy" {
  name        = "${var.environment}-lambda-ssm-restricted-policy"
  description = "Allows Lambda to send SSM commands to specific EC2 instances"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:SendCommand",
          "ssm:GetCommandInvocation"
        ]
        Resource = [
          "arn:aws:ssm:${var.region}::document/AWS-RunShellScript",
          "arn:aws:ec2:${var.region}:${data.aws_caller_identity.current.account_id}:instance/${aws_instance.scanner_ec2_instance.id}"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_copy_to_ec2_s3_access_ssm_policy" {
  role       = aws_iam_role.lambda_copy_to_ec2_exec_role.name
  policy_arn = aws_iam_policy.lambda_ssm_policy.arn
}

resource "aws_iam_role_policy_attachment" "lambda_copy_to_ec2_logs_policy" {
  role       = aws_iam_role.lambda_copy_to_ec2_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}