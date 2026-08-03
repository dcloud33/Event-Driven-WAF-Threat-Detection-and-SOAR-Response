################ CLOUDWATCH WAF LOGS

resource "aws_cloudwatch_log_group" "waf_logs" {
  name              = "aws-waf-logs-api-logs"
  retention_in_days = 30
}

resource "aws_wafv2_web_acl_logging_configuration" "example" {
  log_destination_configs = [aws_cloudwatch_log_group.waf_logs.arn]
  resource_arn            = aws_wafv2_web_acl.waf_rest_api.arn
}

############## EVENTBRIDGE PIPE LOGS

resource "aws_cloudwatch_log_group" "pipe_logs" {
  name              = "/aws/vendedlogs/pipes/pipe-logs"
  retention_in_days = 30
}













