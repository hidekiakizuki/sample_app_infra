resource "aws_dynamodb_table" "terraform_state_lock" {
  name                        = "terraform-state-lock"
  billing_mode                = "PROVISIONED"
  read_capacity               = 1
  write_capacity              = 1
  hash_key                    = "LockID"
  deletion_protection_enabled = true

  attribute {
    name = "LockID"
    type = "S"
  }
}
