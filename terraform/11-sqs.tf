########## SQS Dead letter Queue

resource "aws_sqs_queue" "pipe_dlq" {
  name                      = "pipe-dlq"
  max_message_size          = 2048
  message_retention_seconds = 86400
  receive_wait_time_seconds = 10

}
