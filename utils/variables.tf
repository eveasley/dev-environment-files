########################################
# GLOBALS
########################################
variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-2"
}

variable "aws_profile" {
  description = "AWS CLI profile"
  type        = string
  default     = "default"
}

variable "environment" {
  description = "Deployment environment (dev, prod)"
  type        = string
  default     = "dev"
}

########################################
# NETWORK & CLUSTER
########################################
variable "vpc_id" {
  description = "VPC ID for ECS & EFS"
  type        = string
}

variable "subnet_ids" {
  description = "Private subnet IDs (one per AZ) for ECS tasks & EFS mount targets"
  type        = list(string)
}

variable "cluster_name" {
  description = "Name of the ECS cluster to create or use"
  type        = string
  default     = "monitoring-cluster"
}

variable "zscaler_ips" {
  description = "List of Zscaler egress CIDRs allowed to hit the ALB"
  type        = list(string)
  default     = []
}

variable "route_table_ids" {
  description = "List of route table IDs for the S3 Gateway VPC Endpoint"
  type        = list(string)
  default     = []
}

variable "private_route_table_ids" {
  description = "List of private route table IDs to update with NAT gateway route"
  type        = list(string)
}


########################################
# EFS
########################################
variable "name_prefix" {
  description = "Prefix to use for naming shared EFS resources"
  type        = string
  default     = "shared-config"
}

########################################
# LOKI
########################################
variable "loki_bucket_name" {
  description = "Name of the S3 bucket for Loki"
  type        = string
  default     = "ryn-ops-loki-logs"
}

variable "ec2_sg_id" {
  description = "Security group ID for EC2 instances that need access to EFS"
  type        = string
  default     = "sg-0dbf5dd980a99f8e6"
}


variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    Environment = "dev"
    Project     = "obs-stack"
  }
}
