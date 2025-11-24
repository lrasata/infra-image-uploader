resource "null_resource" "npm_install_get_presigned_url_lambda" {
  provisioner "local-exec" {
    working_dir = "${path.module}/lambda_get_presigned_url" # TODO
    command     = "npm ci"
  }
}


data "archive_file" "lambda_get_presigned_url_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda_get_presigned_url"
  output_path = "${path.module}/lambda_get_presigned_url.zip"

  depends_on = [null_resource.npm_install_get_presigned_url_lambda]
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

resource "aws_lambda_function" "get_presigned_url" {
  function_name = "${var.environment}-get-presigned-url-lambda"
  runtime       = "nodejs20.x"
  handler       = "getPresignedUrl.handler"

  filename         = data.archive_file.lambda_get_presigned_url_zip.output_path
  source_code_hash = data.archive_file.lambda_get_presigned_url_zip.output_base64sha256

  role = aws_iam_role.lambda_upload_exec_role.arn

  environment {
    variables = {
      REGION             = var.region
      EXPIRATION_TIME_S  = var.lambda_upload_presigned_url_expiration_time_s
      UPLOAD_BUCKET      = aws_s3_bucket.s3_bucket_uploads.bucket
      API_GW_AUTH_SECRET = local.auth_secret
      UPLOAD_FOLDER      = local.UPLOAD_FOLDER
      USE_S3_ACCEL       = var.enable_transfer_acceleration
      PARTITION_KEY      = local.partition_key
      SORT_KEY           = local.sort_key
    }
  }

  depends_on = [data.archive_file.lambda_get_presigned_url_zip, aws_iam_role.lambda_upload_exec_role]
}

# IAM Policy for S3 access
resource "aws_iam_policy" "lambda_upload_policy" {
  name        = "${var.environment}-lambda-upload-policy"
  description = "Provide lambda permissions to upload to S3"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["s3:GetObject", "s3:PutObject"]
        Effect   = "Allow"
        Resource = "${aws_s3_bucket.s3_bucket_uploads.arn}/*"
      },
      {
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Effect   = "Allow"
        Resource = data.aws_secretsmanager_secret.file_upload_secrets.arn
      }
    ]
  })
}

# Attach policy to role
resource "aws_iam_role_policy_attachment" "lambda_uploads_policy_attach" {
  role       = aws_iam_role.lambda_upload_exec_role.name
  policy_arn = aws_iam_policy.lambda_upload_policy.arn
}

# Give lambda minimal permissions including : logs:CreateLogGroup, logs:CreateLogStream, logs:PutLogEvents
resource "aws_iam_role_policy_attachment" "lambda_upload_logging" {
  role       = aws_iam_role.lambda_upload_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}