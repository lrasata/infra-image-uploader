data "archive_file" "lambda_process_uploaded_file_zip" {
  type       = "zip"
  source_dir = var.lambda_process_uploaded_file_dir
  output_path = "${path.module}/lambda_process_uploaded_file.zip"

  excludes   = ["node_modules/.bin/*"]
}

resource "aws_iam_role" "lambda_process_uploaded_file_exec_role" {
  name = "${var.environment}-lambda-process-uploaded-file-exec-role"

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

  timeout     = 30  # seconds
  memory_size = var.lambda_memory_size_mb # more memory = faster processing - depending on the max size of the upload file, this can be adjusted

  environment {
    variables = {
      BUCKET_AV_ENABLED = var.use_bucketav
      UPLOAD_FOLDER     = local.UPLOAD_FOLDER
      THUMBNAIL_FOLDER  = local.THUMBNAIL_FOLDER
      DYNAMO_TABLE      = aws_dynamodb_table.files_metadata.name
      PARTITION_KEY      = var.dynamodb_partition_key
    }
  }
}

# IAM Policy for S3 access
resource "aws_iam_policy" "gt_s3_access_policy" {
  name        = "${var.environment}-lambda-process-uploaded-file-policy"
  description = "Allow Lambda to access S3 upload bucket for read and update"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow",
        Action   = ["dynamodb:PutItem"],
        Resource = aws_dynamodb_table.files_metadata.arn
      },
      {
        Action = ["s3:GetObject", "s3:GetObjectVersion", "s3:ListBucket", "s3:PutObject"]
        Effect = "Allow"
        Resource = [
          "${aws_s3_bucket.s3_bucket_uploads.arn}/*",
          "${aws_s3_bucket.s3_bucket_uploads.arn}"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_gt_access_policy_attach" {
  role       = aws_iam_role.lambda_process_uploaded_file_exec_role.name
  policy_arn = aws_iam_policy.gt_s3_access_policy.arn
}

resource "aws_iam_role_policy_attachment" "lambda_gt_logs_policy" {
  role       = aws_iam_role.lambda_process_uploaded_file_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}