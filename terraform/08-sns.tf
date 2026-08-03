resource "aws_sns_topic" "critical_sns" {
  name = "critical-sns-topic"
}
resource "aws_sns_topic_subscription" "sns_subscription" {
  topic_arn = aws_sns_topic.critical_sns.arn
  protocol  = "email"
  endpoint  = var.email_endpoint
}

# Connect the EventBridge rule to the SNS topic
resource "aws_cloudwatch_event_target" "critical_sns_target" {
  rule      = aws_cloudwatch_event_rule.critical_findings.name
  target_id = "SendCriticalAlertToSNS"
  arn       = aws_sns_topic.critical_sns.arn
}


############# SNS for Pipe Dead letter queue

resource "aws_sns_topic" "pipe_dlq-sns" {
  name = "pipe-dlq-sns"
}
resource "aws_sns_topic_subscription" "dlq_sns_subscription" {
  topic_arn = aws_sns_topic.pipe_dlq-sns.arn
  protocol  = "email"
  endpoint  = var.email_endpoint
}







