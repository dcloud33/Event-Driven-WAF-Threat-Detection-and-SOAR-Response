variable "test_user_password" {
  type      = string
  sensitive = true
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "email_endpoint"{
    type = string
    default = "wheeling2346@gmail.com"

}

variable "project_name"{
  type = string
  default = "armageddon-project"
}

variable "user_pool_name"{
  type = string
  default = "test_user_pool"

}

variable "domain_name"{
  type = string
  default = "dcloud33-test-auth"
}

variable "user_name"{
  type = string
  default = "dcloud33"

}




