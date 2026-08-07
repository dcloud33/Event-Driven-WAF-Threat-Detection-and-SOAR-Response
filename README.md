# AWS WAF Threat Detection, SOAR Automation, Fault Isolation, and Executive Reporting Platform

## Project Overview

This project implements an end-to-end AWS security operations platform that combines:

- Amazon Cognito authentication
- API Gateway protection
- AWS WAF threat detection
- Amazon Bedrock AI analysis
- Threat correlation and SOAR automation
- EventBridge Pipe fault isolation
- SQS DLQ monitoring
- Executive security reporting

The platform automatically detects, analyzes, correlates, responds to, and reports on security threats while providing operational monitoring and fault isolation.

---

## Architecture Overview

```text
Client
 │
 ▼
Amazon Cognito
 │
 ▼
API Gateway REST API
 │
 ▼
AWS WAF Web ACL
 │
 ▼
CloudWatch Logs
 │
 ▼
DynamoDB (waf-events)
 │
 ▼
waf-bedrock-analyzer
 │
 ▼
Amazon Bedrock
 │
 ▼
waf-threat-correlation
 │
 ▼
DynamoDB (waf-correlation-findings)
 │
 ▼
EventBridge
 │
 ▼
soar-response-agent
 │
 ├──► security-incidents
 │
 └──► SNS Alerts

Additional Services:
- EventBridge Pipe + DLQ Monitoring
- Executive Reporting Platform
```
![Architecure Diagram](architecture/eventdriven-security-pipeline.pdf)

## Core Components

### Authentication

- Amazon Cognito User Pool
- Groups:
  - admin
  - user

### API Layer

Resources:

- GET /python
- GET /node

Deployment Stage:

```text
prod
```

### AWS WAF

Provides:

- Managed rule protection
- Malicious request filtering
- Web application security monitoring

---

## DynamoDB Tables

### waf-events

Stores raw WAF events and analyzer results.

Partition Key:

```text
event_id
```

### waf-correlation-findings

Stores correlated security findings.

Partition Key:

```text
finding_id
```

### security-incidents

Stores SOAR-generated incidents.

Partition Key:

```text
incident_id
```

---

## Lambda Functions

### waf-bedrock-analyzer

Purpose:

- Reads WAF events
- Uses Amazon Bedrock for analysis
- Generates AI-driven threat insights

Environment Variables:

```text
WAF_EVENTS_TABLE=waf-events
BEDROCK_MODEL_ID=<model-id>
MAX_EVENTS=<number>
```

---

### waf-threat-correlation

Purpose:

- Correlates related attack activity
- Generates threat findings
- Sends custom EventBridge events

---

### soar-response-agent

Purpose:

- Creates incidents
- Publishes SNS notifications
- Performs automated response actions

---

## EventBridge Automation

### Analyzer Schedule

```text
waf-bedrock-analyzer-schedule
rate(5 minutes)
```

### Correlation Schedule

```text
waf-threat-correlation-schedule
rate(5 minutes)
```

---

# Phase 2 - EventBridge Pipe Fault Isolation

## Overview

This enhancement adds fault isolation and monitoring to EventBridge Pipes using:

- Amazon SQS Dead-Letter Queue
- CloudWatch Logs
- CloudWatch Alarm
- Amazon SNS Notifications

### Architecture

```text
EventBridge Pipe
 │
 ├──► EventBridge Event Bus
 │
 ├──► CloudWatch Logs
 │
 └──► Amazon SQS (pipe-dlq)
           │
           ▼
   CloudWatch Alarm
           │
           ▼
     Amazon SNS
           │
           ▼
 Engineer Notification
```

## Components

### SNS Topic

```text
pipe_dlq_sns
```

### SQS Dead-Letter Queue

```text
pipe-dlq
```

### CloudWatch Alarm

Metric:

```text
ApproximateNumberOfMessagesVisible
```

Threshold:

```text
>= 1
```

### Pipe Log Group

```text
/aws/vendedlogs/pipes/pipe-findings-to-eventbridge
```

---

# Phase 3 - Executive Security Reporting

## Overview

Lab 12B extends the platform with executive-level reporting capabilities.

The solution:

- Reads security events
- Reads threat findings
- Reads security incidents
- Uses Amazon Bedrock to generate summaries
- Produces PDF and JSON reports
- Stores reports in Amazon S3
- Executes automatically on schedule

### Architecture

```text
EventBridge Scheduler
        │
        ▼
executive-dashboard-agent
        │
        ├──► waf-events
        ├──► waf-correlation-findings
        ├──► security-incidents
        │
        ▼
Amazon Bedrock
        │
        ▼
PDF / JSON Reports
        │
        ▼
Amazon S3
        │
        ▼
CloudWatch Logs
```

## Executive Reporting Lambda

Function:

```text
executive-dashboard-agent
```

Handler:

```text
executive_dashboard_agent.lambda_handler
```

Required Dependency:

```text
reportlab==4.4.3
```

### Environment Variables

```text
WAF_EVENTS_TABLE=waf-events
CORRELATION_FINDINGS_TABLE=waf-correlation-findings
SECURITY_INCIDENTS_TABLE=security-incidents
SNS_TOPIC_ARN=<sns-topic-arn>
BEDROCK_MODEL_ID=<model-id>
ENABLE_BEDROCK=true
REPORT_PERIOD_HOURS=24
MAX_ITEMS_PER_TABLE=5000
REPORT_BUCKET=<executive-report-bucket>
REPORT_PREFIX=executive-reports
ORGANIZATION_NAME=SEIR Cloud Security
REPORT_TITLE=Executive Security Report
```

---

## End-to-End Workflow

1. User authenticates through Cognito.
2. Requests are processed by API Gateway.
3. AWS WAF evaluates requests.
4. Events are stored in DynamoDB.
5. Bedrock analyzes WAF activity.
6. Threat correlation identifies attack patterns.
7. SOAR automation creates incidents.
8. SNS alerts are sent.
9. EventBridge Pipe failures are isolated through SQS DLQ.
10. CloudWatch alarms notify engineers.
11. Executive reports are generated and stored in S3.

---

## Final Verification Checklist

- Cognito User Pool
- Cognito Groups
- API Gateway REST API
- Cognito Authorizer
- AWS WAF Web ACL
- CloudWatch Logging
- waf-events Table
- waf-bedrock-analyzer Lambda
- waf-threat-correlation Lambda
- security-incidents Table
- SNS Topic and Subscription
- SOAR Response Agent
- EventBridge Schedules
- EventBridge Pipe DLQ
- CloudWatch Alarm
- Executive Dashboard Agent
- Amazon S3 Report Storage

---

## Outcome

This platform delivers a complete AI-powered cloud-native Security Operations Center (SOC) solution on AWS. It provides threat detection, AI analysis, automated response, fault isolation, operational monitoring, and executive reporting.