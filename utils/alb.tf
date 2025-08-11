locals {
  ecs_tasks_sg_id = module.cluster.ecs_sg_id
}

resource "aws_security_group" "alb" {
  name        = "${var.name_prefix}-${var.environment}-alb-sg"
  description = "Allow HTTP from Zscaler only"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = length(var.zscaler_ips) > 0 ? var.zscaler_ips : ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.name_prefix}-${var.environment}-alb-sg"
    Environment = var.environment
  }
}

resource "aws_lb" "app" {
  name               = "${var.name_prefix}-${var.environment}-alb"
  internal           = true
  load_balancer_type = "application"
  subnets            = var.subnet_ids
  security_groups    = [aws_security_group.alb.id]

  idle_timeout = 60

  tags = {
    Name        = "${var.name_prefix}-${var.environment}-alb"
    Environment = var.environment
  }
}

resource "aws_lb_target_group" "loki" {
  name        = "${var.name_prefix}-${var.environment}-loki-tg"
  port        = 3100
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    protocol            = "HTTP"
    path                = "/ready"
    port                = "3100"
    interval            = 30
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = merge(
  var.tags,
  {
    Name = "${var.name_prefix}-${var.environment}-alb-sg"
  }
)

}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.loki.arn
  }
}

resource "aws_security_group_rule" "allow_http_from_alb" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  security_group_id        = local.ecs_tasks_sg_id           
  source_security_group_id = aws_security_group.alb.id     
  description              = "Allow HTTP from ALB"
}

resource "aws_security_group_rule" "allow_loki_from_alb" {
  type                     = "ingress"
  from_port                = 3100
  to_port                  = 3100
  protocol                 = "tcp"
  security_group_id        = local.ecs_tasks_sg_id
  source_security_group_id = aws_security_group.alb.id
  description              = "Allow Loki from ALB"
}

resource "aws_security_group_rule" "allow_prometheus_from_alb" {
  type                     = "ingress"
  from_port                = 9090
  to_port                  = 9090
  protocol                 = "tcp"
  security_group_id        = local.ecs_tasks_sg_id
  source_security_group_id = aws_security_group.alb.id
  description              = "Allow Prometheus from ALB"
}

resource "aws_security_group_rule" "allow_grafana_from_alb" {
  type                     = "ingress"
  from_port                = 3000
  to_port                  = 3000
  protocol                 = "tcp"
  security_group_id        = local.ecs_tasks_sg_id
  source_security_group_id = aws_security_group.alb.id
  description              = "Allow Grafana from ALB"
}
