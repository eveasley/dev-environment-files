resource "aws_security_group" "efs_mount" {
  count       = var.attach_efs ? 1 : 0
  name        = "${var.name_prefix}-${var.environment}-efs-mount-sg"
  vpc_id      = var.vpc_id
  description = "Allow NFS from ECS tasks"

  ingress {
    from_port = 2049
    to_port   = 2049
    protocol  = "tcp"
    security_groups = [
      var.ecs_sg_id,
      var.ec2_sg_id
    ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.name_prefix}-${var.environment}-efs-mount-sg"
      Environment = var.environment
    }
  )
}

resource "aws_efs_file_system" "this" {
  count           = var.attach_efs ? 1 : 0
  creation_token  = "${var.name_prefix}-${var.environment}-efs"
  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"

  tags = merge(
    var.tags,
    {
      Name        = "${var.name_prefix}-${var.environment}-efs"
      Environment = var.environment
    }
  )
}

resource "aws_efs_mount_target" "this" {
  count          = var.attach_efs ? length(var.subnet_ids) : 0
  file_system_id = aws_efs_file_system.this[0].id
  subnet_id      = var.subnet_ids[count.index]
  security_groups = [aws_security_group.efs_mount[0].id]
}

resource "aws_efs_access_point" "this" {
  count          = var.attach_efs ? 1 : 0
  file_system_id = aws_efs_file_system.this[0].id

  posix_user {
    uid = 1000
    gid = 1000
  }

  root_directory {
    path = "/${var.name_prefix}"

    creation_info {
      owner_uid   = 1000
      owner_gid   = 1000
      permissions = "0755"
    }
  }
}
