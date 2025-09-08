# Enable GuardDuty in the region
resource "aws_guardduty_detector" "guard_duty_detector_main" {
  enable = true
}

resource "aws_inspector2_enabler" "malware_protection" {
  # Required attribute specifying which resources to monitor
  resource_types = ["EC2"]

  # Use your current account ID here
  account_ids = [data.aws_caller_identity.current.account_id]
}