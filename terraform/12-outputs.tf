output "api_gateway_invoke_url"{
    value = "${aws_api_gateway_stage.stage_production.invoke_url}/python?name=test"
}

output "cognito_user_pool_client_id" {
  description = "Cognito user pool app client ID"
  value       = aws_cognito_user_pool_client.userpool_client.id
}












