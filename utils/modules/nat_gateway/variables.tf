variable "vpc_id" {
  description = "The VPC ID where NAT gateways will be deployed"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs to deploy NAT gateways"
  type        = list(string)
}

variable "environment" {
  description = "Deployment environment (e.g., dev, prod)"
  type        = string
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
