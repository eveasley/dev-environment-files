module "efs" {
  source      = "./modules/efs"
  vpc_id      = var.vpc_id
  subnet_ids  = var.subnet_ids
  ecs_sg_id   = module.cluster.ecs_sg_id
  ec2_sg_id   = var.ec2_sg_id
  name_prefix = var.name_prefix
  environment = var.environment
  tags        = var.tags
  attach_efs  = true
}

module "cluster" {
  source          = "./modules/cluster"
  cluster_name    = var.cluster_name
  vpc_id          = var.vpc_id
  route_table_ids = var.route_table_ids
  tags            = var.tags
  region          = var.region
  subnet_ids      = var.subnet_ids
  # No need for efs_file_system_id etc. here
}
resource "aws_s3_bucket" "configs" {
  bucket = "metrics-conf-${var.environment}"
  tags = {
    Name        = "configs-bucket"
    Environment = var.environment
  }
}

resource "aws_s3_bucket_versioning" "configs_versioning" {
  bucket = aws_s3_bucket.configs.id
  versioning_configuration {
    status = "Enabled"
  }
}

data "aws_iam_policy_document" "efs_helper_s3" {
  statement {
    actions   = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::metrics-conf-${var.environment}"]
  }
  statement {
    actions   = ["s3:GetObject", "s3:PutObject"]
    resources = ["arn:aws:s3:::metrics-conf-${var.environment}/*"]
  }
}

resource "aws_iam_policy" "efs_helper_s3" {
  name   = "efs-helper-s3-access"
  policy = data.aws_iam_policy_document.efs_helper_s3.json
}

resource "aws_iam_role_policy_attachment" "efs_helper_s3_attach" {
  role       = "EC2SSMRole-efs-helper"
  policy_arn = aws_iam_policy.efs_helper_s3.arn
}
