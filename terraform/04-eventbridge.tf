# EventBridge
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/scheduler_schedule

# This targets the waf analyzer function
resource "aws_scheduler_schedule" "eventbridge_scheduler" {
  name       = "waf-eventbridge-schedule"
  group_name = "default"

  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression = "rate(5 minutes)"

  target {
    arn      = aws_lambda_function.waf_analyzer_function.arn
    role_arn = aws_iam_role.eventbridge_role.arn
  }
}

# This eventbridge schedule targets the Threat Correlation Lambda
resource "aws_scheduler_schedule" "eventbridge_threat_correlation" {
  name       = "waf-threat-correlation-schedule"
  group_name = "default"

  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression = "rate(10 minutes)"

  target {
    arn      = aws_lambda_function.waf_threat_correlation_function.arn
    role_arn = aws_iam_role.eventbridge_role_2.arn
  }
}

# Eventbridge event rule

resource "aws_cloudwatch_event_rule" "soar_findings" {
  name        = "waf-threat-findings"
  description = "Triggers the SOAR Lambda for MEDIUM and HIGH severity WAF findings."

  event_pattern = jsonencode({
    source = [
      "seir.waf.correlation"
    ]

    "detail-type" = [
      "WAF Threat Finding Created"
    ]

    detail = {
      severity = [
        "MEDIUM",
        "HIGH"
      ]
    }
  })
}

# Lambda Permissions for EventBridge to invoke the SOAR Lambda
#TODO:complete this out
resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.soar_response_function.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.soar_findings.arn
}



resource "aws_cloudwatch_event_target" "soar_lambda_target" {
  rule      = aws_cloudwatch_event_rule.soar_findings.name
  target_id = "SendFindingToSoar"
  arn       = aws_lambda_function.soar_response_function.arn
}

# EventBridge rule that matches CRITICAL findings only
resource "aws_cloudwatch_event_rule" "critical_findings" {
  name        = "waf-critical-findings"
  description = "Routes CRITICAL WAF threat findings to the critical alert SNS topic."

  event_pattern = jsonencode({
    source = [
      "seir.waf.correlation"
    ]

    "detail-type" = [
      "WAF Threat Finding Created"
    ]

    detail = {
      severity = [
        "CRITICAL"
      ]
    }
  })
}

resource "aws_cloudwatch_event_target" "critical_soar_target" {
  rule      = aws_cloudwatch_event_rule.critical_findings.name
  target_id = "SendCriticalFindingToSoar"
  arn       = aws_lambda_function.soar_response_function.arn
}

resource "aws_lambda_permission" "allow_critical_eventbridge" {
  statement_id  = "AllowCriticalExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.soar_response_function.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.critical_findings.arn
}

################### Scheduler

resource "aws_scheduler_schedule" "executive_report_schedule" {
  name       = "daily-executive-security-report"
  group_name = "default"

  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression          = "cron(0 12 * * ? *)"
  schedule_expression_timezone = "America/New_York"

  target {
    arn      = aws_lambda_function.exec_dashboard_function.arn
    role_arn = aws_iam_role.executive_scheduler_role.arn

    input = jsonencode({
      report_type = "daily"
    })
  }
}
















































