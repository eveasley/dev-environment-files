variable "cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
}

variable "tags" {
  description = "Tags to apply to the ECS cluster"
  type        = map(string)
  default     = {}
}

variable "vpc_id" {
  description = "VPC ID where Fargate tasks & EFS will live"
  type        = string
}


variable "route_table_ids" {
  description = "List of route table IDs for the S3 VPC endpoint"
  type        = list(string)
}

variable "region" {
  description = "AWS region (passed from root)"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for VPC endpoints and ECS tasks"
  type        = list(string)
}

# EFS
variable "efs_file_system_id" {
  description = "EFS File System ID"
  type        = string
  default     = ""
}

variable "efs_access_point_id" {
  description = "EFS Access Point ID"
  type        = string
  default     = ""
}

variable "efs_sg_id" {
  description = "Security group ID for EFS mount target"
  type        = string
  default     = ""
}