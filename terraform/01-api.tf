locals{
  project = var.project_name
}

############## API GATEWAY REST API

resource "aws_api_gateway_rest_api" "rest_api" {
  name = "${local.project}tf_rest_api"
}


################ API GATEWAY RESOURCES


# Creates the /python resource.
resource "aws_api_gateway_resource" "python_resource" {
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  parent_id   = aws_api_gateway_rest_api.rest_api.root_resource_id
  path_part   = "python"
}

# Creates the /node resource.
resource "aws_api_gateway_resource" "node_resource" {
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  parent_id   = aws_api_gateway_rest_api.rest_api.root_resource_id
  path_part   = "node"
}


################# COGNITO USER POOL AUTHORIZER


resource "aws_api_gateway_authorizer" "gateway_authorizer" {
  name          = "CognitoUserPoolAuthorizer"
  type          = "COGNITO_USER_POOLS"
  rest_api_id   = aws_api_gateway_rest_api.rest_api.id
  provider_arns = [aws_cognito_user_pool.access_user_pool.arn]

  identity_source = "method.request.header.Authorization"
}


################# API GATEWAY METHODS


# Protects GET /python with the Cognito user pool authorizer.
#
# OAuth authorization scopes are not used.
# The Python Lambda function will inspect the cognito:groups
# token claim to determine whether the user has access.
resource "aws_api_gateway_method" "python_method" {
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  resource_id = aws_api_gateway_resource.python_resource.id
  http_method = "GET"

  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.gateway_authorizer.id
}

# Protects GET /node with the Cognito user pool authorizer.
#
# OAuth authorization scopes are not used.
# The Node.js Lambda function will inspect the cognito:groups
# token claim to determine whether the user has access.
resource "aws_api_gateway_method" "node_method" {
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  resource_id = aws_api_gateway_resource.node_resource.id
  http_method = "GET"

  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.gateway_authorizer.id
}


############ LAMBDA PROXY INTEGRATIONS


resource "aws_api_gateway_integration" "python_integration" {
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  resource_id = aws_api_gateway_resource.python_resource.id
  http_method = aws_api_gateway_method.python_method.http_method

  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  uri                     = aws_lambda_function.python_function.invoke_arn
}

resource "aws_api_gateway_integration" "node_integration" {
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  resource_id = aws_api_gateway_resource.node_resource.id
  http_method = aws_api_gateway_method.node_method.http_method

  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  uri                     = aws_lambda_function.node_function.invoke_arn
}

############## API GATEWAY DEPLOYMENT


resource "aws_api_gateway_deployment" "api_deployment" {
  rest_api_id = aws_api_gateway_rest_api.rest_api.id

  /*
  The redeployment hash changes when an API Gateway resource,
  authorizer, method, or integration changes.

  This causes Terraform to create a new API deployment.
  */
  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.python_resource.id,
      aws_api_gateway_resource.node_resource.id,

      aws_api_gateway_authorizer.gateway_authorizer.id,
      aws_api_gateway_authorizer.gateway_authorizer.identity_source,

      aws_api_gateway_method.python_method.id,
      aws_api_gateway_method.python_method.authorization,
      aws_api_gateway_method.python_method.authorizer_id,

      aws_api_gateway_method.node_method.id,
      aws_api_gateway_method.node_method.authorization,
      aws_api_gateway_method.node_method.authorizer_id,

      aws_api_gateway_integration.python_integration.id,
      aws_api_gateway_integration.node_integration.id
    ]))
  }

  /*
  API Gateway deployments are snapshots.

  Terraform creates the new deployment before destroying
  the previous deployment.
  */
  lifecycle {
    create_before_destroy = true
  }

  /*
  Ensures the methods and integrations are created before
  Terraform creates the deployment snapshot.
  */
  depends_on = [
    aws_api_gateway_method.python_method,
    aws_api_gateway_method.node_method,
    aws_api_gateway_integration.python_integration,
    aws_api_gateway_integration.node_integration
  ]
}

################## API GATEWAY PRODUCTION STAGE


resource "aws_api_gateway_stage" "stage_production" {
  rest_api_id   = aws_api_gateway_rest_api.rest_api.id
  deployment_id = aws_api_gateway_deployment.api_deployment.id
  stage_name    = "prod"
}