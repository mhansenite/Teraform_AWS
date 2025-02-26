output "security_group_ids" {
  description = "Map of security group names to their IDs"
  value = {
    for k, v in aws_security_group.security_groups : k => v.id
  }
}

output "security_group_arns" {
  description = "Map of security group names to their ARNs"
  value = {
    for k, v in aws_security_group.security_groups : k => v.arn
  }
} 