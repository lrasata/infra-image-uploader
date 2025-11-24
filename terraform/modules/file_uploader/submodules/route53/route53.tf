# -------------------------
# ROUTE 53 ALIAS RECORD
# -------------------------
data "aws_route53_zone" "main" {
  name         = "epic-trip-planner.com" # this has to be static to allow retrieval of the  Route 53 Hosted Zone
  private_zone = false
}