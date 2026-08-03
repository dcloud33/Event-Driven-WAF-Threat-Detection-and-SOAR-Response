data "aws_caller_identity" "current" {}



resource "aws_s3_bucket" "executive_reports" {
  bucket = "executive-reports-bucket${data.aws_caller_identity.current.account_id}"

  force_destroy = true


}












































