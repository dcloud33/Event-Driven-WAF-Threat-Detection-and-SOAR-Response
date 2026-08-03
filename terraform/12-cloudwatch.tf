resource "aws_cloudwatch_metric_alarm" "alarm_pipe_dlq" {
  alarm_name                = "pipe-dlq-has-messages"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = 1
  metric_name               = "ApproximateNumberOfMessagesVisible"
  namespace                 = "AWS/SQS"
  period                    = 120
  statistic                 = "Maximum"
  threshold                 = 1
  alarm_description         = "This is for messages in dead letter queue"
  

  dimensions = {
    QueueName = "${aws_sqs_queue.pipe_dlq.name}"
  }

  alarm_actions = ["${aws_sns_topic.pipe_dlq-sns.arn}"]

  treat_missing_data = "notBreaching"

}