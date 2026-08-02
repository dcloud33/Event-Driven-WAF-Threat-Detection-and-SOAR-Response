############## Node lambda function code

data "archive_file" "lambda_node" {
  type        = "zip"
  source_file = "../src/node-lambda.js"
  output_path = "../lambda_scripts/node.zip"
}

resource "aws_lambda_function" "node_function" {
  filename         = data.archive_file.lambda_node.output_path
  function_name    = "my_node_function"
  role             = aws_iam_role.lambda_role.arn
  handler          = "node-lambda.handler"
  source_code_hash = data.archive_file.lambda_node.output_base64sha256

  runtime = "nodejs24.x"
}


###################### Python

data "archive_file" "lambda_python" {
  type        = "zip"
  source_file = "../src/chewbacca-python-lambda.py"
  output_path = "../lambda_scripts/python.zip"
}

resource "aws_lambda_function" "python_function" {
  filename         = data.archive_file.lambda_python.output_path
  function_name    = "my_python_function"
  role             = aws_iam_role.lambda_role.arn
  handler          = "chewbacca-python-lambda.lambda_handler"
  source_code_hash = data.archive_file.lambda_python.output_base64sha256

  runtime = "python3.14"
}

########### WAF Analyzer Lambda
data "archive_file" "waf_analyzer_lambda" {
  type        = "zip"
  source_file = "../src/waf_bedrock_analyzer.py"
  output_path = "../lambda_scripts/waf_bedrock_analyzer.zip"
}

resource "aws_lambda_function" "waf_analyzer_function" {
  filename         = data.archive_file.waf_analyzer_lambda.output_path
  function_name    = "waf-analyzer"
  role             = aws_iam_role.waf_analyzer_role.arn # Create Role
  handler          = "waf_bedrock_analyzer.lambda_handler"
  source_code_hash = data.archive_file.waf_analyzer_lambda.output_base64sha256
  environment {
    variables = {
      WAF_LOG_GROUP    = aws_cloudwatch_log_group.waf_logs.name
      DYNAMODB_TABLE   = aws_dynamodb_table.waf_events.name
      BEDROCK_MODEL_ID = "global.anthropic.claude-haiku-4-5-20251001-v1:0"
      LOOKBACK_MINUTES = "10"
      MAX_LOG_EVENT    = "20"
    }
  }
  timeout = 120
  runtime = "python3.14"
}


################# Threat Correlation Lambda
data "archive_file" "waf_threat_correlation" {
  type        = "zip"
  source_file = "../src/waf_threat_correlation_agent.py"
  output_path = "../lambda_scripts/waf_threat_correlation.zip"
}

resource "aws_lambda_function" "waf_threat_correlation_function" {
  filename         = data.archive_file.waf_threat_correlation.output_path
  function_name    = "waf-threat"
  role             = aws_iam_role.correlation_agent_role.arn # Create role
  handler          = "waf_threat_correlation_agent.lambda_handler"
  source_code_hash = data.archive_file.waf_threat_correlation.output_base64sha256
  timeout          = 120
  environment {
    variables = {
      WAF_EVENTS_TABLE           = aws_dynamodb_table.waf_events.name
      CORRELATION_FINDINGS_TABLE = aws_dynamodb_table.waf_correlation_table.name
      BEDROCK_MODEL_ID           = "global.anthropic.claude-haiku-4-5-20251001-v1:0"
      MINIMUM_EVENT_COUNT        = "3"
      MAX_LOG_EVENT              = "20"
      ADMIN_URI_KEYWORDS         = "admin,login,signin,auth,token,cognito"
    }
  }

  runtime = "python3.14"
}



############### Soar Response Agent Lambda
data "archive_file" "soar_response_agent" {
  type        = "zip"
  source_file = "../src/soar_response_agent.py"
  output_path = "../lambda_scripts/soar_response_agent.zip"
}

resource "aws_lambda_function" "soar_response_function" {
  filename         = data.archive_file.soar_response_agent.output_path
  function_name    = "soar-response"
  role             = aws_iam_role.soar_response_agent_role.arn # Create role
  handler          = "soar_response_agent.lambda_handler"
  source_code_hash = data.archive_file.soar_response_agent.output_base64sha256

  timeout = 120

  environment {
    variables = {
      SECURITY_INCIDENTS_TABLE   = aws_dynamodb_table.security_incidents_table.name
      CORRELATION_FINDINGS_TABLE = aws_dynamodb_table.waf_correlation_table.name
      SNS_TOPIC_ARN              = aws_sns_topic.critical_sns.arn
      BEDROCK_MODEL_ID           = "global.anthropic.claude-haiku-4-5-20251001-v1:0"
      ENABLE_BEDROCK             = "true"
    }
  }




  runtime = "python3.14"
}

################# Executive Dashboard Agent
data "archive_file" "exec_dashboard_agent" {
  type        = "zip"
  source_file = "../src/executive_dashboard_agent.py"
  output_path = "../lambda_scripts/executive_dashboard_agent.zip"
}

resource "aws_lambda_function" "exec_dashboard_function" {
  filename         = data.archive_file.exec_dashboard_agent.output_path
  function_name    = "executive-dashboard-agent"
  role             = aws_iam_role.executive_agent_role.arn # Create role
  handler          = "executive_dashboard_agent.lambda_handler"
  source_code_hash = data.archive_file.exec_dashboard_agent.output_base64sha256


  layers = [
    aws_lambda_layer_version.reportlab.arn
  ]

  memory_size = 1024
  timeout     = 120

  ephemeral_storage {
    size = 512
  }

  environment {
    variables = {
      WAF_EVENTS_TABLE           = aws_dynamodb_table.waf_events.name
      SECURITY_INCIDENTS_TABLE   = aws_dynamodb_table.security_incidents_table.name
      CORRELATION_FINDINGS_TABLE = aws_dynamodb_table.waf_correlation_table.name
      SNS_TOPIC_ARN              = aws_sns_topic.critical_sns.arn
      BEDROCK_MODEL_ID           = "global.anthropic.claude-haiku-4-5-20251001-v1:0"
      ENABLE_BEDROCK             = "true"
      REPORT_PERIOD_HOURS        = "24"
      MAX_ITEMS_PER_TABLE        = "5000"
      REPORT_BUCKET              = aws_s3_bucket.executive_reports.bucket
      REPORT_PREFIX              = "executive-reports"
      ORGANIZATION_NAME          = "SEIR Cloud Security"
      REPORT_TITLE               = "Executive Security Report"
    }
  }

  runtime = "python3.12"
}

############################## Compliance-agent:

resource "aws_lambda_function" "compliance_agent" {
  filename      = "${path.module}/../lambda_scripts/compliance-agent.zip"
  function_name = "compliance-agent"
  role          = aws_iam_role.compliance_agent_role.arn
  handler       = "compliance_agent.lambda_handler"
  source_code_hash = filebase64sha256(
    "${path.module}/../lambda_scripts/compliance-agent.zip"
  )

  architectures = ["x86_64"]

  # This is so that we can reuse the existing ReportLab layer
  layers = [
    aws_lambda_layer_version.reportlab.arn
  ]

  timeout     = 120
  memory_size = 1024

  environment {
    variables = {
      CONTROLS_FILE             = "/var/task/controls.json"
      COMPLIANCE_EVIDENCE_TABLE = aws_dynamodb_table.compliance_evidence.name
      REPORT_BUCKET             = aws_s3_bucket.executive_reports.bucket
      REPORT_PREFIX             = "compliance-reports"
      COMPLIANCE_FRAMEWORKS     = "NIST CSF 2.0"
      BEDROCK_MODEL_ID          = "global.anthropic.claude-haiku-4-5-20251001-v1:0"
      ENABLE_BEDROCK            = "true"
      ORGANIZATION_NAME         = "SEIR Cloud Security"
      REPORT_TITLE              = "Compliance Evidence Report"
      UNEVALUATED_STATUS        = "REVIEW"
    }
  }

  depends_on = [aws_lambda_layer_version.reportlab]

  runtime = "python3.12"


}






















































































