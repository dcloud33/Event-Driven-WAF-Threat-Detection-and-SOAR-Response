# Event Driven Architecture Diagram
 User
 &darr;
 Amazon Cognito
 &darr;
 API Gateway
 &darr;
 WAF
 &darr;
 WAF-Logs
 &darr;
 waf-bedrock-analyzer(Lambda Function) &larr; Eventbridge Schedule
 &darr;
 waf-events(DynamoDB Table)
 &darr;
 waf-threat-correlation-agent(Lambda Function) &larr; Eventbridge Schedule
 &darr;
 waf-correlation-findings(DynamoDB Table)
 &darr;
 DynamoDB Stream
 &darr;
 Eventbridge Pipe
 &darr;
 Eventbridge Eventbus(routes to matching rules)
 &darr;
 Eventbridge Pipe

 
 

















































