output "service_name" {
  value = aws_ecs_service.service.name
}

output "service_id" {
  value = aws_ecs_service.service.id
}

output "security_group_id" {
  value = aws_security_group.fargate_service.id
} 