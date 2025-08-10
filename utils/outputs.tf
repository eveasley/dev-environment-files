########################################
# GLOBAL OUTPUTS
########################################
output "region" {
  description = "AWS region"
  value       = var.region
}

########################################
# ECS/EFS OUTPUTS
########################################
output "ecs_cluster_id" {
  description = "ID of the ECS cluster"
  value       = module.cluster.cluster_id
}

output "ecs_tasks_sg_id" {
  description = "Security Group ID attached to ECS task ENIs"
  value       = module.cluster.ecs_sg_id
}

output "efs_sg_id" {
  description = "Security Group ID for EFS mount targets"
  value       = module.efs.efs_sg_id
}

output "efs_file_system_id" {
  description = "ID of the shared EFS filesystem"
  value       = module.efs.efs_file_system_id
}

output "efs_access_point_id" {
  description = "ID of the EFS access point"
  value       = module.efs.efs_access_point_id
}
########################################
# LOKI OUTPUTS
########################################
# output "loki_task_role_arn" {
#   description = "ARN of the ECS task role for Loki"
#   value       = aws_iam_role.loki_task.arn
# }

output "s3_endpoint" {
  description = "S3 endpoint for Loki"
  value       = "s3.${var.region}.amazonaws.com"
}
# ECS SERVICE LOKI
# output "loki_service_name" {
#   description = "Name of the Loki ECS service"
#   value       = module.loki.service_name
# }

# output "loki_service_arn" {
#   description = "ARN of the Loki ECS service"
#   value       = module.loki.service_arn
# }

# output "bucket_name" {
#   description = "Name of the S3 bucket"
#   value       = aws_s3_bucket.loki_logs.bucket
# }

# output "ecs_execution_role_arn" {
#   description = "ARN of the ECS execution role"
#   value       = aws_iam_role.ecs_execution.arn
# }

output "efs_mount_target_ids" {
  description = "Map of subnet ID → EFS mount target ID"
  value       = module.efs.efs_mount_target_ids
}

# Cluster ARN 
output "ecs_cluster_arn" {
  description = "ARN of the ECS cluster"
  value       = module.cluster.cluster_arn
}

# ALB & TARGET-GROUP
output "alb_sg_id" {
  description = "Security Group for the ALB"
  value       = aws_security_group.alb.id
}

########################################
# NETWORKING OUTPUTS
########################################
output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = aws_lb.app.arn
}
#
output "alb_dns_name" {
  description = "DNS name of the ALB"
  value       = aws_lb.app.dns_name
}

output "loki_target_group_arn" {
  description = "ARN of the Loki target group"
  value       = aws_lb_target_group.loki.arn
}

output "loki_listener_arn" {
  description = "ARN of the HTTP listener"
  value       = aws_lb_listener.http.arn
}

