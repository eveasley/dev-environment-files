########################################
# ECS FARGATE CLUSTER
########################################
data "aws_region" "current" {}

resource "aws_ecs_cluster" "this" {
  name = var.cluster_name
  tags = var.tags

}

resource "aws_ecs_cluster_capacity_providers" "this" {
  cluster_name       = aws_ecs_cluster.this.name
  capacity_providers = ["FARGATE"]

  default_capacity_provider_strategy {
    capacity_provider = "FARGATE"
    weight = 1
    base = 0
  }
}

#  Security group for Fargate tasks
resource "aws_security_group" "ecs_tasks" {
  name        = "${var.cluster_name}-tasks-sg"
  description = "Fargate task ENIs for ${var.cluster_name}"
  vpc_id      = var.vpc_id

  # pull images, write logs, mount EFS, etc.
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # allow HTTP (port 80) from the Internet, for the ALB
  ingress {
    description = "Allow HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # allow Loki traffic (3100) from anywhere
  ingress {
    description = "Allow Loki UI/API"
    from_port   = 3100
    to_port     = 3100
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # allow Prometheus traffic (9090) from anywhere
  ingress {
    description = "Allow Prometheus"
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # allow Grafana (3000) from anywhere
  ingress {
    description = "Allow Grafana"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = merge(var.tags, { "Name" = "${var.cluster_name}-tasks-sg" })
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = var.route_table_ids

  tags = merge(
    var.tags,
    { Name = "${var.cluster_name}-s3-endpoint" }
  )
}

resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id             = var.vpc_id
  service_name       = "com.amazonaws.${var.region}.ecr.api"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = var.subnet_ids
  security_group_ids = [aws_security_group.ecs_tasks.id]

  tags = merge(
    var.tags,
    { Name = "${var.cluster_name}-ecr-api-endpoint" }
  )
}

resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id             = var.vpc_id
  service_name       = "com.amazonaws.${var.region}.ecr.dkr"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = var.subnet_ids
  security_group_ids = [aws_security_group.ecs_tasks.id]

  tags = merge(
    var.tags,
    { Name = "${var.cluster_name}-ecr-dkr-endpoint" }
  )
}
########################################
# IF ATTACH_EFS
########################################

# EFS security group 
resource "aws_security_group" "efs_mount" {
  count       = var.attach_efs ? 1 : 0
  name        = "${var.efs_name_prefix != "" ? var.efs_name_prefix : var.cluster_name}-efs-sg"
  description = "Allow NFS from Fargate tasks for ${var.cluster_name}"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_tasks.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { "Name" = "${var.efs_name_prefix != "" ? var.efs_name_prefix : var.cluster_name}-efs-sg" })
}

# EFS filesystem 
resource "aws_efs_file_system" "this" {
  count            = var.attach_efs ? 1 : 0
  creation_token   = "${var.efs_name_prefix != "" ? var.efs_name_prefix : var.cluster_name}-efs"
  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"
  tags             = merge(var.tags, { "Name" = "${var.efs_name_prefix != "" ? var.efs_name_prefix : var.cluster_name}-efs" })
}

# Single mount target per subnet/AZ 
resource "aws_efs_mount_target" "this" {
  for_each       = var.attach_efs ? toset(var.efs_subnet_ids) : toset([])
  file_system_id = aws_efs_file_system.this[0].id
  subnet_id      = each.value
  security_groups = [
    aws_security_group.efs_mount[0].id
  ]
}

# EFS Access Point 
resource "aws_efs_access_point" "this" {
  count          = var.attach_efs ? 1 : 0
  file_system_id = aws_efs_file_system.this[0].id

  posix_user {
    uid = 1000
    gid = 1000
  }

  root_directory {
    path = "/${var.efs_name_prefix != "" ? var.efs_name_prefix : var.cluster_name}"

    creation_info {
      owner_uid   = 1000
      owner_gid   = 1000
      permissions = "0755"
    }
  }
}
