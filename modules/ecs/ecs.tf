variable "master" {}
variable "env" {}
variable "app_name" {}

resource "aws_ecs_cluster" "cluster" {
  name = "${var.master.convention}-${var.env}-${var.app_name}"

  tags = {
    Name = "${var.master.convention}-${var.env}-${var.app_name}"
    Environment = var.env
  }
}

resource "aws_ecs_task_definition" "task" {
  family                   = "${var.master.convention}-${var.env}-${var.app_name}"
  requires_compatibilities = ["FARGATE"]
  network_mode            = "awsvpc"
  cpu                     = 256
  memory                  = 512
  execution_role_arn      = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.master.convention}-ecs_task_execution_role"

  container_definitions = jsonencode([
    {
      name      = "${var.master.convention}-${var.env}-${var.app_name}"
      image     = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.master.region}.amazonaws.com/${var.master.convention}-${var.env}-${var.app_name}:latest"
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
          protocol      = "tcp"
        }
      ]
    }
  ])
}

data "aws_caller_identity" "current" {} 