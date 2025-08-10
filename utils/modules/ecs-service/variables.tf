########################################
# VARIABLES
########################################

variable "name" {
  description = "Logical name for this ECS service (used as family, service name, log‐prefix)"
  type        = string
}

variable "cluster_id" {
  description = "ECS Cluster ID to deploy into"
  type        = string
}

variable "execution_role_arn" {
  description = "ARN of the IAM role that the ECS agent uses to pull images and publish logs"
  type        = string
}

variable "task_role_arn" {
  description = "ARN of the IAM role that your containers will assume"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the service will run"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the service's ENIs"
  type        = list(string)
}

variable "ecs_sg_id" {
  description = "Security Group ID to attach to the service's ENIs"
  type        = string
}

variable "image" {
  description = "Container image to run"
  type        = string
}

variable "cpu" {
  description = "Task-level CPU units"
  type        = number
}

variable "memory" {
  description = "Task-level memory (MiB)"
  type        = number
}

variable "container_port" {
  description = "Port the container listens on"
  type        = number
}

variable "desired_count" {
  description = "Number of tasks to keep running"
  type        = number
  default     = 1
}

variable "env_vars" {
  description = "Map of environment variables to inject into the container"
  type        = map(string)
  default     = {}
}

variable "secrets" {
  description = "Map of container ENV names → ARN of Secrets Manager secret"
  type        = map(string)
  default     = {}
}

# EFS‐related inputs
variable "efs_file_system_id" {
  description = "EFS FileSystem ID"
  type        = string
  default     = ""
}

variable "efs_access_point_id" {
  description = "EFS Access Point ID (leave empty if not using EFS)"
  type        = string
  default     = ""
}

variable "efs_sg_id" {
  description = "Security Group ID for EFS mount targets (leave empty if not using EFS)"
  type        = string
  default     = ""
}

variable "load_balancers" {
   description = "List of ALB attachments: container_name, container_port,   target_group_arn"
   type = list(object({
     container_name   = string
     container_port   = number
     target_group_arn = string
   }))
   default = []
}

variable "mount_certs" {
  description = "Whether to mount the shared certs directory (/certs on EFS) into /etc/ssl/certs"
  type        = bool
  default     = false
}

variable "command" {
  description = "Container command override (e.g., [\"-config.file=/mnt/config/local-config.yaml\"])"
  type        = list(string)
  default     = []
}

variable "efs_container_path" {
  description = "Where to mount EFS inside the container (defaults to /<service-name> if empty)"
  type        = string
  default     = ""
}

variable "region" {
  description = "AWS region"
  type        = string
}