resource "aws_cloudwatch_event_rule" "guardduty_malware_rule" {
  name        = "${var.environment}-guard-duty-malware-rule"
  description = "Trigger Lambda when GuardDuty reports EC2 malware findings"
  event_pattern = jsonencode({
    source      = ["aws.guardduty"]
    detail-type = ["GuardDuty Finding"]
    detail = {
      type = ["Recon:EC2/Malware"]
    }
  })
}

resource "aws_cloudwatch_event_target" "guardduty_malware_lambda_target" {
  rule      = aws_cloudwatch_event_rule.guardduty_malware_rule.name
  target_id = "${var.environment}-guard-duty-quarantine-lambda-target"
  arn       = aws_lambda_function.guardduty_quarantine.arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "${var.environment}-allow-execution-from-event-bridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.guardduty_quarantine.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.guardduty_malware_rule.arn
}
