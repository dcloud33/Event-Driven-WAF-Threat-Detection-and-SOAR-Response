# Lambda Function IAM Permissions:

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "lambda_role" {
  name               = "lambda_execution_role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}


resource "aws_iam_role_policy_attachment" "test_attach" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}


# this is to give lambda permissions to invoke the function for python and node
resource "aws_lambda_permission" "python_lambda_permission" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.python_function.function_name
  principal     = "apigateway.amazonaws.com"
}

resource "aws_lambda_permission" "node_lambda_permission" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.node_function.function_name
  principal     = "apigateway.amazonaws.com"
}

################# WAF Analyzer Function Role

resource "aws_iam_role" "waf_analyzer_role" {
  name               = "waf-analyzer-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy_attachment" "analyzer_attach" {
  role       = aws_iam_role.waf_analyzer_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}


# Lambda Permissions for DynamoDB put logs in waf-events table

# resource "aws_iam_policy" "dynamodb_waf_analyzer" {
#   name = "dynamodb-waf-analyzer-policy"

#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect = "Allow"
#         Action = [
#           "dynamodb:PutItem"
#         ]
#         Resource = [aws_dynamodb_table.waf_events.arn]
#       }
#     ]
#   })
# }

# resource "aws_iam_role_policy_attachment" "lambda_dynamodb_token_tracking_attach" {
#   role       = aws_iam_role.waf_analyzer_role.name
#   policy_arn = aws_iam_policy.dynamodb_waf_analyzer.arn
# }

# Lambda WAF/Bedrock Permissions
resource "aws_iam_policy" "lambda_waf_bedrock_analyzer_policy" {
  name = "waf-analyzer-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:FilterLogEvents"

        ]
        Resource = ["${aws_cloudwatch_log_group.waf_logs.arn}:*"]
      },
      {
        Effect = "Allow"
        Action = [
          "bedrock:InvokeModel"

        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem"
        ]
        Resource = [aws_dynamodb_table.waf_events.arn]
      }

    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_waf_bedrock_" {
  role       = aws_iam_role.waf_analyzer_role.name
  policy_arn = aws_iam_policy.lambda_waf_bedrock_analyzer_policy.arn
}

########################### Correlation Agent Function Role

resource "aws_iam_role" "correlation_agent_role" {
  name               = "correlation-agent-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy_attachment" "correlation_logs" {
  role       = aws_iam_role.correlation_agent_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

################### Correlation Role Policies

resource "aws_iam_policy" "correlation_role_policy" {
  name = "waf-correlation-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "bedrock:InvokeModel"

        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:Scan",
          "dynamodb:Query"
        ]
        Resource = [aws_dynamodb_table.waf_events.arn]
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem"

        ]
        Resource = [aws_dynamodb_table.waf_correlation_table.arn]
      }

    ]
  })
}

resource "aws_iam_role_policy_attachment" "waf_analyzer_logs" {
  role       = aws_iam_role.correlation_agent_role.name
  policy_arn = aws_iam_policy.correlation_role_policy.arn
}
########################### SOAR response agent

resource "aws_iam_role" "soar_response_agent_role" {
  name               = "soar-response-agent-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy_attachment" "soar_logs" {
  role       = aws_iam_role.soar_response_agent_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_policy" "soar_role_policy" {
  name = "soar-response-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "bedrock:InvokeModel"

        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem"

        ]
        Resource = [aws_dynamodb_table.security_incidents_table.arn]
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:UpdateItem",
          "dynamodb:GetItem"

        ]
        Resource = [aws_dynamodb_table.waf_correlation_table.arn]
      },
      {
        Effect = "Allow"
        Action = [
          "sns:Publish"

        ]
        Resource = [aws_sns_topic.critical_sns.arn]
      }

    ]
  })
}

resource "aws_iam_role_policy_attachment" "soar_policy_attach" {
  role       = aws_iam_role.soar_response_agent_role.name
  policy_arn = aws_iam_policy.soar_role_policy.arn
}



########################## Executive report agent

resource "aws_iam_role" "executive_agent_role" {
  name               = "exec-report-agent-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy_attachment" "executive_logs" {
  role       = aws_iam_role.executive_agent_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}


resource "aws_iam_role_policy" "executive_dashboard_policy" {
  name = "ExecutiveDashboardAccessPolicy"
  role = aws_iam_role.executive_agent_role.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid    = "ReadSecurityData"
        Effect = "Allow"

        Action = [
          "dynamodb:Scan"
        ]

        Resource = [
          aws_dynamodb_table.waf_events.arn,
          aws_dynamodb_table.waf_correlation_table.arn,
          aws_dynamodb_table.security_incidents_table.arn
        ]
      },
      {
        Sid    = "InvokeBedrock"
        Effect = "Allow"

        Action = [
          "bedrock:InvokeModel"
        ]

        Resource = "*"
      },
      {
        Sid    = "WriteExecutiveReports"
        Effect = "Allow"

        Action = [
          "s3:PutObject"
        ]

        Resource = "${aws_s3_bucket.executive_reports.arn}/executive-reports/*"
      }
    ]
  })
}

###################### compliance-agent role

resource "aws_iam_role" "compliance_agent_role" {
  name               = "compliance-agent-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy_attachment" "compliance_attach" {
  role       = aws_iam_role.compliance_agent_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

###################: compliance policy IAM
resource "aws_iam_policy" "compliance_policy" {
  name = "compliance-agent-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:DescribeTable",
          "dynamodb:Scan",
          "dynamodb:Query",
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:BatchWriteItem"

        ]
        Resource = [
          aws_dynamodb_table.compliance_evidence.arn,
          aws_dynamodb_table.waf_events.arn,
          aws_dynamodb_table.waf_correlation_table.arn,
          aws_dynamodb_table.security_incidents_table.arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject"
          
        ]
        Resource = "${aws_s3_bucket.executive_reports.arn}/compliance-reports/*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
          
        ]
        Resource = [aws_s3_bucket.executive_reports.arn]
      },
      {
        Effect = "Allow"
        Action = [
          "bedrock:InvokeModel"

        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "events:DescribeRule",    # gets the configuration of an EventBridge Rule
          "scheduler:GetSchedule",  # gets the configuration of an EventBridge Scheduler schedule
          "sns:GetTopicAttributes", # gets the attribute of a specific sns topic
          "lambda:GetFunction"      # it retrieves detailed info about a specific Lambda function

        ]
        Resource = "*"
      }

    ]
  })
}

resource "aws_iam_role_policy_attachment" "compliance_agent_policy_attach" {
  role       = aws_iam_role.compliance_agent_role.name
  policy_arn = aws_iam_policy.compliance_policy.arn
}

################## EventBridge Assume Role: Data

data "aws_iam_policy_document" "eventbridge_execution_role_1" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["scheduler.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

# Eventbridge Schedule 1 Role
resource "aws_iam_role" "eventbridge_role" {
  name               = "eventbridge_execution_role_1"
  assume_role_policy = data.aws_iam_policy_document.eventbridge_execution_role_1.json
}


resource "aws_iam_policy" "eventbridge_invoke_lambda_policy_1" {
  name = "eventbridge-invoke-waf-analyzer-policy_1"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "lambda:InvokeFunction"
        ]
        Resource = aws_lambda_function.waf_analyzer_function.arn
      }
    ]
  })
}


resource "aws_iam_role_policy_attachment" "eventbridge_policy_attach_1" {
  role       = aws_iam_role.eventbridge_role.name
  policy_arn = aws_iam_policy.eventbridge_invoke_lambda_policy_1.arn
}


###################### EVENTBRIDGE SCHEDULE 2

data "aws_iam_policy_document" "eventbridge_execution_role_2" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["scheduler.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

################### EVENTBRIDGE SCHEDULE 2 ROLE
resource "aws_iam_role" "eventbridge_role_2" {
  name               = "eventbridge_execution_role_2"
  assume_role_policy = data.aws_iam_policy_document.eventbridge_execution_role_2.json
}


resource "aws_iam_policy" "eventbridge_2_invoke_lambda_policy" {
  name = "eventbridge-invoke-waf-analyzer-policy_2"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "lambda:InvokeFunction"
        ]
        Resource = aws_lambda_function.waf_threat_correlation_function.arn
      }
    ]
  })
}


resource "aws_iam_role_policy_attachment" "eventbridge_policy_attach_2" {
  role       = aws_iam_role.eventbridge_role_2.name
  policy_arn = aws_iam_policy.eventbridge_2_invoke_lambda_policy.arn
}


#########################  EVENTBRIDGE PIPES ROLE

data "aws_iam_policy_document" "pipes_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["pipes.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "pipe" {
  name               = "eventbridge-pipe-role"
  assume_role_policy = data.aws_iam_policy_document.pipes_assume.json
}

data "aws_iam_policy_document" "pipe" {
  statement {
    sid = "StreamEventsDynamoDB"
    actions = [
      "dynamodb:DescribeStream",
      "dynamodb:GetRecords",
      "dynamodb:GetShardIterator",
      "dynamodb:ListStreams"
    ]
    resources = [aws_dynamodb_table.waf_correlation_table.stream_arn]
  }

  statement {
    sid = "MessageSQSPermission"
    actions = [
      "sqs:SendMessage",

    ]
    resources = [aws_sqs_queue.pipe_dlq.arn]
  }
    statement {
    sid = "PipeLogsPermission"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"

    ]
    resources = [aws_sqs_queue.pipe_dlq.arn]
  }

  statement {
    sid       = "PublishToDefaultEventBus"
    actions   = ["events:PutEvents"]
    resources = ["arn:${data.aws_partition.current.partition}:events:${var.aws_region}:${data.aws_caller_identity.current.account_id}:event-bus/default"]
  }


}

resource "aws_iam_role_policy" "pipe" {
  name   = "eventbridge-pipe-policy"
  role   = aws_iam_role.pipe.id
  policy = data.aws_iam_policy_document.pipe.json
}

##################### SNS TOPIC POLICY
data "aws_iam_policy_document" "critical_sns_policy" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }

    actions = [
      "sns:Publish"
    ]

    resources = [
      aws_sns_topic.critical_sns.arn
    ]

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"

      values = [
        aws_cloudwatch_event_rule.critical_findings.arn
      ]
    }
  }
}

resource "aws_sns_topic_policy" "critical_sns" {
  arn    = aws_sns_topic.critical_sns.arn
  policy = data.aws_iam_policy_document.critical_sns_policy.json
}

############################# SCHEDULE ROLE

data "aws_iam_policy_document" "executive_scheduler_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["scheduler.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "executive_scheduler_role" {
  name = "executive-report-scheduler-role"

  assume_role_policy = data.aws_iam_policy_document.executive_scheduler_assume_role.json
}

resource "aws_iam_role_policy" "executive_scheduler_policy" {
  name = "invoke-executive-report-lambda"
  role = aws_iam_role.executive_scheduler_role.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "lambda:InvokeFunction"
        ]

        Resource = aws_lambda_function.exec_dashboard_function.arn
      }
    ]
  })
}











































