# ==================================================
# COGNITO USER POOL
# ==================================================

resource "aws_cognito_user_pool" "access_user_pool" {
  name = "test_user_pool"

  mfa_configuration        = "ON"
  auto_verified_attributes = ["email"]

  software_token_mfa_configuration {
    enabled = true
  }

  password_policy {
    minimum_length    = 8
    require_uppercase = true
    require_lowercase = true
    require_numbers   = true
    require_symbols   = false
  }

  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }
}

# ==================================================
# COGNITO USER POOL CLIENT
# ==================================================

resource "aws_cognito_user_pool_client" "userpool_client" {
  name         = "user_pool_client"
  user_pool_id = aws_cognito_user_pool.access_user_pool.id

  generate_secret = false

  callback_urls = [
    "https://localhost/callback"
  ]

  logout_urls = [
    "https://localhost/callback"
  ]

  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["code"]

  allowed_oauth_scopes = [
    "email",
    "openid",
    "profile"
  ]

  supported_identity_providers = [
    "COGNITO"
  ]

  explicit_auth_flows = [
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_AUTH",
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_ADMIN_USER_PASSWORD_AUTH"
  ]
}

# ==================================================
# COGNITO DOMAIN
# ==================================================

resource "aws_cognito_user_pool_domain" "domain" {
  domain       = "dcloud33-test-auth"
  user_pool_id = aws_cognito_user_pool.access_user_pool.id
}

# ==================================================
# COGNITO GROUPS
# ==================================================

resource "aws_cognito_user_group" "admin_group" {
  name         = "admin"
  description  = "Administrators with elevated application access"
  user_pool_id = aws_cognito_user_pool.access_user_pool.id

  precedence = 1
}

resource "aws_cognito_user_group" "user_group" {
  name         = "user"
  description  = "Regular users with basic application access"
  user_pool_id = aws_cognito_user_pool.access_user_pool.id

  precedence = 2
}

# ==================================================
# COGNITO USER
# ==================================================

resource "aws_cognito_user" "example" {
  user_pool_id = aws_cognito_user_pool.access_user_pool.id
  username     = "dcloud33"

  password       = var.test_user_password
  message_action = "SUPPRESS"

  attributes = {
    email          = "wheeling2346@gmail.com"
    email_verified = true
  }
}

# ==================================================
# GROUP MEMBERSHIP
# ==================================================

resource "aws_cognito_user_in_group" "dcloud33_admin" {
  user_pool_id = aws_cognito_user_pool.access_user_pool.id
  group_name   = aws_cognito_user_group.admin_group.name
  username     = aws_cognito_user.example.username
}