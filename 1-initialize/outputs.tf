output "terraform_state_bucket" {
  description = "Name of the S3 bucket for Terraform state"
  value       = aws_s3_bucket.terraform_state.id
}

output "terraform_state_bucket_arn" {
  description = "ARN of the S3 bucket for Terraform state"
  value       = aws_s3_bucket.terraform_state.arn
}

output "terraform_state_lock_table" {
  description = "Name of the DynamoDB table for state locking"
  value       = aws_dynamodb_table.terraform_state_lock.name
}

output "terraform_state_kms_key" {
  description = "ID of the KMS key used for state encryption"
  value       = aws_s3_bucket_server_side_encryption_configuration.terraform_state.rule[0].apply_server_side_encryption_by_default.sse_algorithm
}
