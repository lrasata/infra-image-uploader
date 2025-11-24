# -------------------------
# ROUTE 53 ALIAS RECORD
# -------------------------
data "aws_route53_zone" "main" {
  name         = "epic-trip-planner.com" # this has to be static to allow retrieval of the  Route 53 Hosted Zone
  private_zone = false
}

resource "aws_route53_record" "api" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = aws_api_gateway_domain_name.api.domain_name
  type    = "A"

  alias {
    name                   = aws_api_gateway_domain_name.api.regional_domain_name
    zone_id                = aws_api_gateway_domain_name.api.regional_zone_id
    evaluate_target_health = false
  }
}