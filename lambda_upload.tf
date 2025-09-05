data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda"
  output_path = "${path.module}/lambda.zip"
}

resource "aws_iam_role" "lambda_upload_exec_role" {
  name = "${var.environment}-lambda-upload-exec-role"

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


resource "aws_iam_role_policy" "lambda_s3_upload" {
  name = "${var.environment}-lambda-s3-upload-role-policy"
  role = aws_iam_role.lambda_upload_exec_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject"
        ]
        Resource = "${aws_s3_bucket.s3_bucket_uploads.arn}/*"
      }
    ]
  })
}

resource "aws_lambda_function" "get_presigned_url" {
  function_name = "${var.environment}-get-presigned-url-lambda"
  runtime       = "python3.11"
  handler       = "get_presigned_url.get_presigned_url_handler"

  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  role = aws_iam_role.lambda_upload_exec_role.arn

  environment {
    variables = {
      REGION             = var.region
      EXPIRATION_TIME_S  = var.lambda_upload_presigned_url_expiration_time_s
      UPLOAD_BUCKET      = aws_s3_bucket.s3_bucket_uploads.bucket
      CUSTOM_AUTH_SECRET = local.auth_secret
    }
  }

  depends_on = [data.archive_file.lambda_zip, aws_iam_role.lambda_upload_exec_role]
}

# IAM Policy for S3 access
resource "aws_iam_policy" "s3_uploads_access_policy" {
  name        = "lambda_uploads_s3_access_policy"
  description = "Allow Lambda to access S3 bucket for pre-signed URL"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["s3:GetObject", "s3:PutObject"]
        Effect   = "Allow"
        Resource = "${aws_s3_bucket.s3_bucket_uploads.arn}/*"
      }
    ]
  })
}

# Attach policy to role
resource "aws_iam_role_policy_attachment" "lambda_uploads_policy_attach" {
  role       = aws_iam_role.lambda_upload_exec_role.name
  policy_arn = aws_iam_policy.s3_uploads_access_policy.arn
}

resource "aws_iam_role_policy_attachment" "lambda_upload_logging" {
  role       = aws_iam_role.lambda_upload_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}


resource "aws_iam_policy" "lambda_secrets_access" {
  name        = "${var.environment}-lambda-secretsmanager-access"
  description = "Allow Lambda to access Secrets Manager"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Effect   = "Allow"
        Resource = data.aws_secretsmanager_secret.image_upload_secrets.arn
      }
    ]
  })
}