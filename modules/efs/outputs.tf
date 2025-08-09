output "efs_sg_id" {
  description = "Security Group ID for EFS mount targets"
  value       = aws_security_group.efs_mount.id
}

output "efs_file_system_id" {
  description = "ID of the EFS file system"
  value       = aws_efs_file_system.this.id
}

output "efs_access_point_id" {
  description = "ID of the EFS access point"
  value       = aws_efs_access_point.this.id
}

output "efs_mount_target_ids" {
  description = "Map of subnet ID → EFS mount target ID"
  value       = { for sid, mt in aws_efs_mount_target.this : sid => mt.id }
}
