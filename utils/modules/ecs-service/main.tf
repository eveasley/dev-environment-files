locals {
  efs_mount_path = var.efs_container_path != "" ? var.efs_container_path : "/${var.name}"
}


########################################
# ECS Task Definition
########################################
resource "aws_cloudwatch_log_group" "this" {
  name              = "/ecs/${var.name}"
  retention_in_days = 14
}

resource "aws_ecs_task_definition" "this" {
  family                   = var.name
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.cpu
  memory                   = var.memory
  execution_role_arn       = var.execution_role_arn
  task_role_arn            = var.task_role_arn

  # Optional EFS volume
  dynamic "volume" {
    for_each = var.efs_file_system_id != "" ? [var.efs_file_system_id] : []
    content {
      name = "efs"

      efs_volume_configuration {
        file_system_id     = volume.value
        transit_encryption = "ENABLED"

        authorization_config {
          access_point_id = var.efs_access_point_id
          iam             = "DISABLED"
        }
      }
    }
  }

  container_definitions = jsonencode([
    merge(
      {
        name      = var.name
        image     = var.image
        cpu       = var.cpu
        memory    = var.memory
        essential = true
        portMappings = [{
          containerPort = var.container_port
          protocol      = "tcp"
        }]
        environment = [
          for k, v in var.env_vars : { name = k, value = v }
        ]
        logConfiguration = {
          logDriver = "awslogs"
          options = {
            awslogs-group         = "/ecs/${var.name}"
            awslogs-region        = var.region
            awslogs-stream-prefix = var.name
          }
        }
      },
      length(var.command) > 0 ? { command = var.command } : {},
      var.efs_file_system_id != "" ? {
        mountPoints = concat(
          [
            {
              sourceVolume  = "efs"
              containerPath = local.efs_mount_path
              readOnly      = false
            }
          ],
          var.mount_certs ? [
            {
              sourceVolume  = "efs"
              containerPath = "/etc/ssl/certs"
              readOnly      = true
            }
          ] : []
        )
      } : {}
    )
  ])
}
# data "aws_region" "current" {}

########################################
# ECS Service
########################################

resource "aws_ecs_service" "this" {
  name            = var.name
  cluster         = var.cluster_id
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = [var.ecs_sg_id]
    assign_public_ip = false
  }
  dynamic "load_balancer" {
    for_each = var.load_balancers
    content {
      container_name   = load_balancer.value.container_name
      container_port   = load_balancer.value.container_port
      target_group_arn = load_balancer.value.target_group_arn
    }
  }


}
