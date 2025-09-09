data "archive_file" "lambda_node_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda_node"
  output_path = "${path.module}/lambda_node.zip"

  excludes = ["node_modules/.bin/*"]
}

resource "aws_iam_role" "lambda_generate_thumbnail_exec_role" {
  name = "${var.environment}-lambda-generate-thumbnail-exec-role"

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

resource "aws_lambda_function" "generate_thumbnail" {
  function_name = "${var.environment}-generate-thumbnail-lambda"
  runtime       = "nodejs20.x"
  handler       = "generateThumbnail.handler"

  filename         = data.archive_file.lambda_node_zip.output_path
  source_code_hash = data.archive_file.lambda_node_zip.output_base64sha256

  role = aws_iam_role.lambda_generate_thumbnail_exec_role.arn

  timeout       = 30  # seconds
  memory_size   = 512 # more memory = faster processing - TODO in Instructions clarify max size of image to upload
}

# IAM Policy for S3 access
resource "aws_iam_policy" "gt_s3_access_policy" {
  name        = "${var.environment}-lambda-generate-thumbnail-policy"
  description = "Allow Lambda to access S3 upload bucket for read and update"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
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
  role       = aws_iam_role.lambda_generate_thumbnail_exec_role.name
  policy_arn = aws_iam_policy.gt_s3_access_policy.arn
}

resource "aws_iam_role_policy_attachment" "lambda_gt_logs_policy" {
  role       = aws_iam_role.lambda_generate_thumbnail_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}