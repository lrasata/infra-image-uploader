# EC2 instance will be monitored by GuardDuty for malware.
# S3 objects copied here can trigger malware scans

resource "aws_iam_role" "ec2_inspector_role" {
  name = "${var.environment}-ec2-inspector-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ec2_policy" {
  role       = aws_iam_role.ec2_inspector_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}


data "aws_ssm_parameter" "amazon_linux_2_ami" {
  name = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}


resource "aws_instance" "scanner_ec2_instance" {
  ami                  = data.aws_ssm_parameter.amazon_linux_2_ami.value
  instance_type        = var.ec2_instance_type
  region               = var.region
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

  tags = {
    Name = "${var.environment}-AmazonLinux2EC2InstanceScanner"
  }
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.environment}-ec2-inspector-profile"
  role = aws_iam_role.ec2_inspector_role.name
}
