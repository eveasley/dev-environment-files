variable "vpc_id" {
  description = "The ID of the VPC"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs"
  type        = list(string)
}

variable "ecs_sg_id" {
  description = "Security group ID for ECS tasks"
  type        = string
}

variable "ec2_sg_id" {
  description = "Security group ID for EC2 instances that need access to EFS"
  type        = string
  default     = "sg-0dbf5dd980a99f8e6"
}

variable "name_prefix" {
  description = "Prefix used for naming resources"
  type        = string
}

variable "environment" {
  description = "Deployment environment (e.g., dev, prod)"
  type        = string
}

variable "attach_efs" {
  description = "Whether to create and attach EFS"
  type        = bool
  default     = false
}
