resource "aws_s3_bucket" "executive_reports" {
  bucket = "executive-reports-bucket007212026"

  force_destroy = true

  tags = {
    Name        = "incident-bucket007212026"
    Environment = "Prod"
  }
}












































