variable "master" {}
variable "env" {}
variable "app_name" {}
variable "vpc_id" {}
variable "subnet_ids" {}
variable "target_group_port" {
  default = 80
}

resource "aws_security_group" "alb" {
  name        = "${var.master.convention}-${var.env}-${var.app_name}-alb-sg"
  description = "Security group for ALB"
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
    Name        = "${var.master.convention}-${var.env}-${var.app_name}-alb-sg"
    Environment = var.env
  }
}

resource "aws_lb" "main" {
  name               = "${var.master.convention}-${var.env}-${var.app_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets           = var.subnet_ids

  tags = {
    Name        = "${var.master.convention}-${var.env}-${var.app_name}-alb"
    Environment = var.env
  }
}

resource "aws_lb_target_group" "app" {
  name        = "${var.master.convention}-${var.env}-${var.app_name}-tg"
  port        = var.target_group_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    healthy_threshold   = 2
    interval           = 30
    protocol           = "HTTP"
    matcher            = "200"
    timeout            = 5
    path              = "/"
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
} 