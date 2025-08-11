#!/bin/bash

REPO_OWNER="YOUR_REPO_OWNER"
REPO_NAME="YOUR_REPO_NAME"
PROJECT_NAME="Infra Roadmap"

# Find the project ID by name
PROJECT_ID=$(gh api graphql -f query='
query($owner: String!, $name: String!) {
  repository(owner: $owner, name: $name) {
    projectsV2(first: 10) {
      nodes {
        id
        title
      }
    }
  }
}' -F owner="$REPO_OWNER" -F name="$REPO_NAME" --jq '.data.repository.projectsV2.nodes[] | select(.title=="'"$PROJECT_NAME"'") | .id')

if [ -z "$PROJECT_ID" ]; then
  echo "Project \"$PROJECT_NAME\" not found!"
  exit 1
fi

# Function to create an issue and add it to the project
create_issue() {
  local title=$1
  local body=$2

  # Create issue
  ISSUE_URL=$(gh issue create -R "$REPO_OWNER/$REPO_NAME" -t "$title" -b "$body" --json url --jq '.url')
  echo "Created issue: $title"

  # Get issue node ID for adding to project
  ISSUE_NODE_ID=$(gh api graphql -f query='
  query($owner: String!, $name: String!, $issueNumber: Int!) {
    repository(owner: $owner, name: $name) {
      issue(number: $issueNumber) {
        id
      }
    }
  }' -F owner="$REPO_OWNER" -F name="$REPO_NAME" -F issueNumber=$(basename "$ISSUE_URL") --jq '.data.repository.issue.id')

  # Add issue to project
  gh api graphql -f query='
  mutation($projectId: ID!, $contentId: ID!) {
    addProjectV2ItemById(input: {projectId: $projectId, contentId: $contentId}) {
      item {
        id
      }
    }
  }' -F projectId="$PROJECT_ID" -F contentId="$ISSUE_NODE_ID" >/dev/null
}

# Define issues with titles and bodies

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

# Loop through and create issues
for issue in "${issues[@]}"; do
  IFS="||" read -r title body <<< "$issue"
  create_issue "$title" "$body"
done

echo "All issues created and added to project \"$PROJECT_NAME\"."
