
resource "aws_wafv2_web_acl" "waf_rest_api" {
  name  = "waf_rest_api"
  scope = "REGIONAL"

  default_action {
    allow {}
  }

  # Moved inline rules,
  # Creating web acl rule to manage rules as a seperate resource, to protect against any deletion
  # ordering errors, especially when it comes to managed rules.

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "waf"
    sampled_requests_enabled   = true
  }

  # Added so Terraform won't manage inline rules 
  lifecycle {
    ignore_changes = [rule]
  }
}

resource "aws_wafv2_web_acl_rule" "common_rule_set" {
  name        = "aws_managed_rules"
  priority    = 2
  web_acl_arn = aws_wafv2_web_acl.waf_rest_api.arn

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
    metric_name                = "aws_managed_rules"
    sampled_requests_enabled   = true
  }
}

resource "aws_wafv2_web_acl_rule" "bad_inputs" {
  name        = "bad_inputs" # Must match existing rule name
  priority    = 1
  web_acl_arn = aws_wafv2_web_acl.waf_rest_api.arn

  override_action {
    none {}
  }

  statement {
    managed_rule_group_statement {
      name        = "AWSManagedRulesKnownBadInputsRuleSet"
      vendor_name = "AWS"
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "bad_inputs"
    sampled_requests_enabled   = true
  }
}

resource "aws_wafv2_web_acl_rule" "blocked_sql_injections" {
  name        = "blocked_sql_injections"
  priority    = 3
  web_acl_arn = aws_wafv2_web_acl.waf_rest_api.arn

  override_action {
    none {}
  }

  statement {
    managed_rule_group_statement {
      name        = "AWSManagedRulesSQLiRuleSet"
      vendor_name = "AWS"
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "blocked_sql_injections"
    sampled_requests_enabled   = true
  }
}

resource "aws_wafv2_web_acl_rule" "rate_limit" {
  name        = "rate-limit"
  priority    = 4
  web_acl_arn = aws_wafv2_web_acl.waf_rest_api.arn

  action {
    block {}
  }

  statement {
    rate_based_statement {
      limit              = 100
      aggregate_key_type = "IP"
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "rate-limit"
    sampled_requests_enabled   = true
  }
}

# this was to associate the web acl with the rest_api resource, basically attaching
# WAF to the Rest API
resource "aws_wafv2_web_acl_association" "api_assoc" {
  resource_arn = aws_api_gateway_stage.stage_production.arn
  web_acl_arn  = aws_wafv2_web_acl.waf_rest_api.arn
}

