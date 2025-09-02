data "aws_secretsmanager_secret" "image_upload_secrets" {
  name = "${var.environment}/image-upload/secrets"
}

data "aws_secretsmanager_secret_version" "image_upload_secrets_value" {
  secret_id = data.aws_secretsmanager_secret.image_upload_secrets.id
}

locals {
  auth_secret = jsondecode(data.aws_secretsmanager_secret_version.image_upload_secrets_value.secret_string)["CUSTOM_AUTH_SECRET"]
}