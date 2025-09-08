resource "aws_iam_role" "lambda_guardduty_quarantine_exec_role" {
  name = "${var.environment}-lambda-guardduty-quarantine-exec-role"

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

resource "aws_lambda_function" "guardduty_quarantine" {
  function_name = "${var.environment}-guardduty-quarantine"
  role          = aws_iam_role.lambda_guardduty_quarantine_exec_role.arn
  runtime       = "python3.11"
  handler       = "handle_malware_findings.handler"

  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      QUARANTINE_BUCKET = aws_s3_bucket.s3_bucket_quarantine.bucket
    }
  }
}

# Attach inline policy for S3 copy/delete
resource "aws_iam_policy" "lambda_s3_quarantine_policy" {
  name        = "${var.environment}-lambda-s3-quarantine-policy"
  description = "Allow Lambda to move infected files to quarantine bucket"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:CopyObject",
          "s3:DeleteObject",
          "s3:GetObject"
        ],
        Resource = [
          "${aws_s3_bucket.s3_bucket_uploads.arn}/*",
          "${aws_s3_bucket.s3_bucket_quarantine.arn}/*"
        ]
      },
      {
        Effect   = "Allow",
        Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_s3_quarantine_attach" {
  role       = aws_iam_role.lambda_guardduty_quarantine_exec_role.name
  policy_arn = aws_iam_policy.lambda_s3_quarantine_policy.arn
}
