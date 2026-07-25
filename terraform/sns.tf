resource "aws_sns_topic" "critical_sns" {
  name = "critical-sns-topic"
}
resource "aws_sns_topic_subscription" "sns_subscription" {
  topic_arn = aws_sns_topic.critical_sns.arn
  protocol  = "email"
  endpoint  = "wheeling2346@gmail.com"
}

# Connect the EventBridge rule to the SNS topic
resource "aws_cloudwatch_event_target" "critical_sns_target" {
  rule      = aws_cloudwatch_event_rule.critical_findings.name
  target_id = "SendCriticalAlertToSNS"
  arn       = aws_sns_topic.critical_sns.arn
}











