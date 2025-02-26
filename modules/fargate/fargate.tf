variable "master" {}
variable "env" {}
variable "app_name" {}
variable "vpc_id" {}
variable "subnet_ids" {}
variable "task_definition_arn" {}
variable "cluster_arn" {}
variable "target_group_arn" {}

resource "aws_security_group" "fargate_service" {
  name        = "${var.master.convention}-${var.env}-${var.app_name}-fargate-sg"
  description = "Security group for Fargate service"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.master.convention}-${var.env}-${var.app_name}-fargate-sg"
    Environment = var.env
  }
}

resource "aws_ecs_service" "service" {
  name            = "${var.master.convention}-${var.env}-${var.app_name}"
  cluster         = var.cluster_arn
  task_definition = var.task_definition_arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = [aws_security_group.fargate_service.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = "${var.master.convention}-${var.env}-${var.app_name}"
    container_port   = 80
  }
} 