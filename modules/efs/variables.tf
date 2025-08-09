variable "vpc_id"      { type = string }
variable "subnet_ids"  { type = list(string) }
variable "ecs_sg_id"   { type = string }
variable "name_prefix" { type = string }
variable "environment"{ type = string }
variable "ec2_sg_id" {
  description = "Security group ID for EC2 instances that need access to EFS"
  type        = string
  default     = "sg-0dbf5dd980a99f8e6"
}