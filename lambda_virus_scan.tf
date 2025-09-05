
resource "aws_iam_role" "lambda_virus_scan_exec_role" {
  name = "${var.environment}-lambda-virus-scan-exec-role"

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


resource "aws_iam_role_policy" "lambda_s3_virus_scan" {
  name = "${var.environment}-lambda-s3-virus-scan-role-policy"
  role = aws_iam_role.lambda_virus_scan_exec_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject"
        ]
        Resource = "${aws_s3_bucket.s3_bucket_quarantine.arn}/*"
      }
    ]
  })

}

resource "aws_lambda_function" "virus_scan" {
  function_name = "${var.environment}-virus-scan-lambda"
  runtime       = "python3.11"
  handler       = "virus_scan.virus_scan_handler"

  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  role = aws_iam_role.lambda_virus_scan_exec_role.arn

  environment {
    variables = {
      QUARANTINE_BUCKET = aws_s3_bucket.s3_bucket_quarantine.bucket
    }
  }

  layers = [var.clamAV_layer_arn]

  depends_on = [data.archive_file.lambda_zip, aws_iam_role.lambda_virus_scan_exec_role]
}


# IAM Policy for S3 access
resource "aws_iam_policy" "s3_virus_scan_access_policy" {
  name        = "lambda_virus_scan_s3_access_policy"
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

resource "aws_iam_policy" "lambda_quarantine_bucket_access" {
  name        = "lambda_quarantine_bucket_access"
  description = "Allow Lambda to put objects in quarantine bucket"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject"
        ]
        Resource = "${aws_s3_bucket.s3_bucket_quarantine.arn}/*"
      }
    ]
  })
}


# Attach policy to role
resource "aws_iam_role_policy_attachment" "lambda_virus_scan_policy_attach" {
  role       = aws_iam_role.lambda_virus_scan_exec_role.name
  policy_arn = aws_iam_policy.s3_virus_scan_access_policy.arn
}

resource "aws_iam_role_policy_attachment" "lambda_quarantine_policy_attach" {
  role       = aws_iam_role.lambda_virus_scan_exec_role.name
  policy_arn = aws_iam_policy.lambda_quarantine_bucket_access.arn
}

resource "aws_iam_role_policy_attachment" "lambda_virus_scan_logging" {
  role       = aws_iam_role.lambda_virus_scan_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}