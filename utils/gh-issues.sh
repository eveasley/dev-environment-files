#!/bin/bash

REPO="YOUR_ORG/YOUR_REPO"
PROJECT_NAME="Infra Roadmap"

declare -a issues=(
  "Create ECS Cluster and Configure Networking||Set up ECS cluster with Fargate, configure VPC, private subnets, route tables, and NAT gateway or TGW routing as needed."
  "Create and Configure EFS||Provision EFS filesystem with access points and security groups, attach to ECS tasks for shared config storage."
  "Provision S3 Buckets for Configs and Logs||Create S3 buckets for storing service config files and Loki logs, set bucket policies and versioning."
  "Set Up IAM Roles and Policies||Define execution and task roles for ECS tasks with permissions for S3, EFS, and AWS services."
  "Create Security Group for ALB||Configure ALB security group allowing trusted IP ranges (e.g., Zscaler) on port 80."
  "Provision ALB and Target Groups||Set up internal ALB with listeners and target groups for Loki, Prometheus, and Grafana."
  "Define Health Checks||Configure health checks on target groups to ensure container task health."
  "Define ECS Task Definitions||Write task definitions for Loki, Prometheus, Grafana, Alloy with environment, resources, EFS mounts."
  "Set Up IAM Roles for ECS Tasks||Attach necessary IAM policies to ECS execution and task roles."
  "Deploy ECS Services and Verify||Launch ECS services and confirm task registration to ALB target groups."
  "Prepare Service Config Files||Organize Loki, Prometheus, Grafana, Alloy config files."
  "Upload Config Files to S3||Upload config files to S3 bucket using automation or AWS CLI."
  "Sync Config Files from S3 to EFS||Configure EC2 or scripts to sync configs from S3 to EFS for ECS tasks."
  "Verify ALB Access and DNS||Confirm ALB DNS accessibility inside VPN."
  "Check Service Logs and Metrics||Review CloudWatch logs and Prometheus metrics to validate service health."
  "Adjust and Tune Infrastructure||Make adjustments on security groups, IAM roles, autoscaling based on testing."
)

for issue in "${issues[@]}"; do
  IFS="||" read -r title body <<< "$issue"
  gh issue create -R "$REPO" -t "$title" -b "$body" -p "$PROJECT_NAME"
  echo "Created issue: $title"
done

echo "All issues created and assigned to project '$PROJECT_NAME'."
