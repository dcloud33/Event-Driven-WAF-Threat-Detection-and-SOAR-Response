###################### EVENTBRIDGE PIPES

resource "aws_pipes_pipe" "findings" {
  name     = "pipe-findings-to-eventbridge"
  role_arn = aws_iam_role.pipe.arn

  source = aws_dynamodb_table.waf_correlation_table.stream_arn

  target = "arn:${data.aws_partition.current.partition}:events:${var.aws_region}:${data.aws_caller_identity.current.account_id}:event-bus/default"



  log_configuration {
    include_execution_data = ["ALL"]
    level                  = "INFO"
    cloudwatch_logs_log_destination {
      log_group_arn = aws_cloudwatch_log_group.pipe_logs.arn
    }
  }

  source_parameters {
    filter_criteria {
      filter {
        pattern = jsonencode({
          eventName = ["INSERT"]

          dynamodb = {
            NewImage = {
              status = {
                S = ["OPEN"]
              }
            }
          }
        })
      }
    }
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/pipes_pipe#argument-reference
    dynamodb_stream_parameters {
      batch_size                    = 1
      starting_position             = "LATEST"
      maximum_retry_attempts        = 3
      maximum_record_age_in_seconds = 3600
      dead_letter_config {
        arn = aws_sqs_queue.pipe_dlq.arn
      }
    }





  }
  # https://docs.aws.amazon.com/eventbridge/latest/userguide/eb-pipes-input-transformation.html
  target_parameters {
    input_template = <<-EOT
  {
    "finding_id": <$.dynamodb.NewImage.finding_id.S>,
    "severity": <$.dynamodb.NewImage.severity.S>,
    "risk_score": <$.dynamodb.NewImage.risk_score.N>
  }
  EOT
  

    eventbridge_event_bus_parameters {
      detail_type = "WAF Threat Finding Created"
      source      = "seir.waf.correlation"
    }
    
  }

  depends_on = [
    aws_iam_role_policy.pipe
  ]
}