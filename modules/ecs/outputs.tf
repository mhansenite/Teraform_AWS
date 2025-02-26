output "cluster_arn" {
  value = aws_ecs_cluster.cluster.arn
}

output "cluster_name" {
  value = aws_ecs_cluster.cluster.name
}

output "task_definition_arn" {
  value = aws_ecs_task_definition.task.arn
}

output "task_definition_family" {
  value = aws_ecs_task_definition.task.family
} 