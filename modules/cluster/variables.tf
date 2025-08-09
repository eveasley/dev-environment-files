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

variable "attach_efs" {
  description = "Whether to create and expose EFS for this cluster"
  type        = bool
  default     = false
}

variable "efs_subnet_ids" {
  description = "Private subnet IDs (one per AZ) to put EFS mount targets in"
  type        = list(string)
  default     = []
}

variable "efs_name_prefix" {
  description = "Name prefix for EFS resources (will fall back to cluster_name if empty)"
  type        = string
  default     = ""
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