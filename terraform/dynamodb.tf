
############## DynamoDB Table: waf-events ################
resource "aws_dynamodb_table" "waf_events" {

  name = "waf-events"

  billing_mode = "PAY_PER_REQUEST"

  hash_key = "event_id"

  attribute {

    name = "event_id"
    type = "S"

  }

  point_in_time_recovery {

    enabled = true

  }

  server_side_encryption {

    enabled = true

  }


}


#     waf-correlation-findings
#    Primary key: finding_id

#   security-incidents
#    Primary key: incident_id

############## DynamoDB Table: waf-correlation-findings ################

resource "aws_dynamodb_table" "waf_correlation_table" {

  name = "waf-correlation-findings"

  billing_mode = "PAY_PER_REQUEST"

  hash_key = "finding_id"

  attribute {
    name = "finding_id"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled = true
  }

  # NEW_IMAGE supplies the complete newly written finding to EventBridge Pipes.
  stream_enabled   = true
  stream_view_type = "NEW_IMAGE"

}





############## DynamoDB Table: security-incidents ################

resource "aws_dynamodb_table" "security_incidents_table" {

  name = "security-incidents"

  billing_mode = "PAY_PER_REQUEST"

  hash_key = "incident_id"

  attribute {

    name = "incident_id"
    type = "S"

  }

  point_in_time_recovery {

    enabled = true

  }

  server_side_encryption {

    enabled = true

  }


}




