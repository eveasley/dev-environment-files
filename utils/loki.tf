########################################
# LOKI S3 BUCKET
########################################

resource "aws_s3_bucket" "loki_logs" {
  bucket = var.loki_bucket_name

  tags = {
    Name = var.loki_bucket_name
  }
}


########################################
# IAM POLICY FOR S3 ACCESS
########################################

data "aws_iam_policy_document" "loki_s3" {
  statement {
    sid     = "AllowLokiListBucket"
    actions = ["s3:ListBucket"]
    resources = [
      aws_s3_bucket.loki_logs.arn
    ]
  }

  statement {
    sid = "AllowLokiGetPutObject"
    actions = [
      "s3:GetObject",
      "s3:PutObject"
    ]
    resources = [
      "${aws_s3_bucket.loki_logs.arn}/*"
    ]
  }
}

resource "aws_iam_policy" "loki_s3" {
  name   = "${var.loki_bucket_name}-s3-policy"
  policy = data.aws_iam_policy_document.loki_s3.json
}

########################################
# ECS EXECUTION ROLE
########################################

resource "aws_iam_role" "ecs_execution" {
  name = "${var.loki_bucket_name}-exec-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_execution_policy" {
  role       = aws_iam_role.ecs_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

########################################
# LOKI TASK ROLE
########################################

resource "aws_iam_role" "loki_task" {
  name = "${var.loki_bucket_name}-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "loki_s3_attach_task" {
  role       = aws_iam_role.loki_task.name
  policy_arn = aws_iam_policy.loki_s3.arn
}

# #######################################
# LOKI ECS SERVICE
# #######################################

# module "loki" {
#   source = "./modules/ecs-service"

#   # service‐specific
#   name               = "loki"
#   image              = "public.ecr.aws/bitnami/grafana-loki:3.5.0"
#   container_port     = 3100
#   cpu                = 512
#   memory             = 1024
#   env_vars           = {}
#   region             = var.region
#   execution_role_arn = aws_iam_role.ecs_execution.arn
#   task_role_arn      = aws_iam_role.loki_task.arn

#   cluster_id = module.cluster.cluster_id
#   ecs_sg_id  = module.cluster.ecs_sg_id

#   vpc_id     = var.vpc_id
#   subnet_ids = var.subnet_ids

#   # opt‐in EFS
#   efs_file_system_id  = module.efs.efs_file_system_id
#   efs_access_point_id = module.efs.efs_access_point_id
#   efs_sg_id           = module.efs.efs_sg_id
#   efs_container_path  = "/mnt/config"
#   command             = ["-config.file=/mnt/config/loki-conf/loki-config.yaml"]
#   load_balancers = [
#     {
#       container_name   = "loki"
#       container_port   = 3100
#       target_group_arn = aws_lb_target_group.loki.arn
#     }
#   ]
#   depends_on = [module.efs]
# }

