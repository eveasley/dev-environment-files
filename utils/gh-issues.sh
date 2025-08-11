#!/bin/bash

REPO="YOUR_ORG/YOUR_REPO"
PROJECT_NAME="Infra Roadmap"

declare -a issues=(
 "Set up Unit and Integration Tests for Terraform Modules||Define and implement automated unit and integration tests for all Terraform modules using tools like Terratest or kitchen-terraform. Ensure tests run locally and in CI."
  "Create GitHub Actions Workflow for Running Tests on Dev Branch||Create a workflow to run Terraform tests on every push or PR to the dev branch including lint, validate, and plan steps. Fail build on test failures."
  "Implement CI Workflow to Build and Push Docker Images||Add steps to GitHub Actions to build Docker images on dev branch changes and push to a container registry with proper tagging."
  "Create GitHub Actions Workflow for Webhook-Based Deployments to Main Branch||Set up a workflow triggered by webhook or merges to main branch that deploys infrastructure and services automatically, optionally with approval."
  "Configure Environment Secrets and Variables for CI/CD||Manage AWS credentials, Terraform backend configs, and Docker registry secrets securely in GitHub Actions secrets."
  "Add Manual Approval Step or Protection for Main Branch Deployments||Add manual approval gates or environment protection rules in GitHub Actions before deploying to main environment."
  "Document CI/CD Workflows and Test Strategy||Write clear documentation explaining the CI/CD pipeline and testing strategy, including how to run tests locally and trigger deployments."
)

for issue in "${issues[@]}"; do
  IFS="||" read -r title body <<< "$issue"
  gh issue create -R "$REPO" -t "$title" -b "$body" -p "$PROJECT_NAME"
  echo "Created issue: $title"
done

echo "All issues created and assigned to project '$PROJECT_NAME'."
