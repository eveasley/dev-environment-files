########################################
# OUTPUTS
########################################
output "cluster_id" {
  description = "ID of the ECS cluster"
  value       = aws_ecs_cluster.this.id
}

output "capacity_providers" {
  description = "List of capacity providers attached to the cluster"
  value       = aws_ecs_cluster_capacity_providers.this.capacity_providers
}

output "default_capacity_provider_strategy" {
  description = "Default capacity provider strategy for the cluster"
  value       = aws_ecs_cluster_capacity_providers.this.default_capacity_provider_strategy
}

output "cluster_arn" {
  description = "ARN of the ECS cluster"
  value       = aws_ecs_cluster.this.arn
}

output "ecs_sg_id" {
  description = "SG ID to attach to Fargate tasks"
  value       = aws_security_group.ecs_tasks.id
}

output "efs_file_system_id" {
  description = "EFS FileSystem ID"
  value       = var.attach_efs ? aws_efs_file_system.this[0].id : ""
}

output "efs_access_point_id" {
  description = "EFS Access Point ID"
  value       = var.attach_efs ? aws_efs_access_point.this[0].id : ""
}

output "efs_sg_id" {
  description = "SG ID for EFS mount targets"
  value       = var.attach_efs ? aws_security_group.efs_mount[0].id : ""
}

output "efs_mount_target_ids" {
  description = "List of EFS mount target IDs"
  value       = var.attach_efs ? [for mt in aws_efs_mount_target.this : mt.id] : []
}
