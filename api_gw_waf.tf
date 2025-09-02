resource "aws_wafv2_web_acl" "api_gw_waf" {
  name        = "${var.environment}-image-uploader-api-gw-waf"
  description = "WAF for API Gateway"
  scope       = "REGIONAL"

  default_action {
    allow {}
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.environment}-imageUploaderApiGwWAF"
    sampled_requests_enabled   = true
  }

  # Managed rule group (common protections)
  rule {
    name     = "${var.environment}-AWSManagedRulesCommonRuleSet"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.environment}-managedRules"
      sampled_requests_enabled   = true
    }
  }

  # Block if header X-Custom-Auth is missing
  rule {
    name     = "${var.environment}-BlockIfMissingCustomHeader"
    priority = 2

    action {
      block {}
    }

    statement {
        not_statement {
            statement {
            size_constraint_statement {
                field_to_match {
                single_header {
                    name = "x-custom-auth" # must be lowercase
                }
                }
                comparison_operator = "GT"   # greater than
                size                = 0      # header length must be > 0
                text_transformation {
                priority = 0
                type     = "NONE"
                }
            }
            }
        }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.environment}-blockMissingCustomHeader"
      sampled_requests_enabled   = true
    }
  }
}

# Associate the WAF with API Gateway stage (not execution_arn)
resource "aws_wafv2_web_acl_association" "api_gw_assoc" {
  resource_arn = aws_api_gateway_stage.api_gateway_stage.arn
  web_acl_arn  = aws_wafv2_web_acl.api_gw_waf.arn
}
