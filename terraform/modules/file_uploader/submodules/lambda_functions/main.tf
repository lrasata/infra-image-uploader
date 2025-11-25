locals {
  upload_folder    = "uploads/"
  thumbnail_folder = "thumbnails/"
}

# ============================================================================
# GET PRESIGNED URL LAMBDA
# ============================================================================

resource "null_resource" "npm_install_get_presigned_url_lambda" {
  provisioner "local-exec" {
    working_dir = "${path.module}/src/lambdas/get_presigned_url"
    command     = "npm ci"
  }
}

data "archive_file" "lambda_get_presigned_url_zip" {
  type        = "zip"
  source_dir  = "${path.module}/src/lambdas/get_presigned_url"
  output_path = "${path.module}/lambda_get_presigned_url.zip"

  depends_on = [null_resource.npm_install_get_presigned_url_lambda]
}

resource "aws_iam_role" "lambda_upload_exec_role" {
  name = "${var.environment}-lambda-upload-exec-role"
  tags = {
    Environment = var.environment
    App         = var.app_id
  }

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

  tags = {
    Name        = "${var.environment}-get-presigned-url-lambda"
    Environment = var.environment
    App         = var.app_id
  }

  environment {
    variables = {
      REGION             = var.region
      EXPIRATION_TIME_S  = var.lambda_upload_presigned_url_expiration_time_s
      UPLOAD_BUCKET      = var.uploads_bucket_id
      API_GW_AUTH_SECRET = var.auth_secret
      UPLOAD_FOLDER      = local.upload_folder
      USE_S3_ACCEL       = var.enable_transfer_acceleration
      PARTITION_KEY      = var.dynamodb_partition_key
      SORT_KEY           = var.dynamodb_sort_key
    }
  }

  depends_on = [data.archive_file.lambda_get_presigned_url_zip, aws_iam_role.lambda_upload_exec_role]
}

resource "aws_iam_policy" "lambda_upload_policy" {
  name        = "${var.environment}-lambda-upload-policy"
  description = "Provide lambda permissions to upload to S3"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["s3:GetObject", "s3:PutObject"]
        Effect   = "Allow"
        Resource = "${var.uploads_bucket_arn}/*"
      },
      {
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Effect   = "Allow"
        Resource = var.secret_arn
      }
    ]
  })
  tags = {
    Environment = var.environment
    App         = var.app_id
  }
}

resource "aws_iam_role_policy_attachment" "lambda_uploads_policy_attach" {
  role       = aws_iam_role.lambda_upload_exec_role.name
  policy_arn = aws_iam_policy.lambda_upload_policy.arn
}

resource "aws_iam_role_policy_attachment" "lambda_upload_logging" {
  role       = aws_iam_role.lambda_upload_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# ============================================================================
# PROCESS UPLOADED FILE LAMBDA
# ============================================================================

data "archive_file" "lambda_process_uploaded_file_zip" {
  type = "zip"
  # source_dir  = "${path.module}/src/lambdas/process_uploaded_file"
  # TODO this should be replaced with local-exec provisioner but executed on CI/CD pipeline
  source_dir  = var.lambda_process_uploaded_file_dir
  output_path = "${path.module}/lambda_process_uploaded_file.zip"

  excludes = ["node_modules/.bin/*"]
}

resource "aws_iam_role" "lambda_process_uploaded_file_exec_role" {
  name = "${var.environment}-lambda-process-uploaded-file-exec-role"
  tags = merge(var.common_tags, { Name = "${var.environment}-lambda-process-uploaded-file-exec-role" }, var.app_id != "" ? { App = var.app_id } : {})



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

resource "aws_lambda_function" "process_uploaded_file" {
  function_name = "${var.environment}-process-uploaded-file-lambda"
  runtime       = "nodejs20.x"
  handler       = "processUploadedFile.handler"

  filename         = data.archive_file.lambda_process_uploaded_file_zip.output_path
  source_code_hash = data.archive_file.lambda_process_uploaded_file_zip.output_base64sha256

  role = aws_iam_role.lambda_process_uploaded_file_exec_role.arn

  timeout     = 30
  memory_size = var.lambda_memory_size_mb

  environment {
    variables = {
      BUCKET_AV_ENABLED = var.use_bucketav
      UPLOAD_FOLDER     = local.upload_folder
      THUMBNAIL_FOLDER  = local.thumbnail_folder
      DYNAMO_TABLE      = var.dynamodb_table_name
      PARTITION_KEY     = var.dynamodb_partition_key
      SORT_KEY          = var.dynamodb_sort_key
    }
  }

  tags = {
    Name        = "${var.environment}-process-uploaded-file-lambda"
    Environment = var.environment
    App         = var.app_id
  }
}

resource "aws_iam_policy" "gt_s3_access_policy" {
  name        = "${var.environment}-lambda-process-uploaded-file-policy"
  description = "Allow Lambda to access S3 upload bucket for read and update"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "dynamodb:Query",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem"
        ],
        Resource = var.dynamodb_table_arn
      },
      {
        Action = ["s3:GetObject", "s3:GetObjectVersion", "s3:ListBucket", "s3:PutObject"]
        Effect = "Allow"
        Resource = [
          "${var.uploads_bucket_arn}/*",
          var.uploads_bucket_arn
        ]
      }
    ]
  })

  tags = {
    Name        = "${var.environment}-lambda-process-uploaded-file-policy"
    Environment = var.environment
    App         = var.app_id
  }
}

resource "aws_iam_role_policy_attachment" "lambda_gt_access_policy_attach" {
  role       = aws_iam_role.lambda_process_uploaded_file_exec_role.name
  policy_arn = aws_iam_policy.gt_s3_access_policy.arn
}

resource "aws_iam_role_policy_attachment" "lambda_gt_logs_policy" {
  role       = aws_iam_role.lambda_process_uploaded_file_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}