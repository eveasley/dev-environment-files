#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

PROFILE="admin"
REGION="us-east-2"
VPC_ID="vpc-0969ce579f19b3ebf"
SUBNET_IDS=("subnet-0cba2d5cb47dd69a2" "subnet-0746bb5310ed0c16f")
SUBNET_ID="${SUBNET_IDS[0]}"
ROLE_NAME="EC2SSMRole-efs-helper"
INSTANCE_PROFILE_NAME="$ROLE_NAME"
HELPER_SG_NAME="efs-helper-sg"
VPCE_SG_NAME="vpce-ssm-sg"
INSTANCE_NAME_TAG="efs-helper"
INSTANCE_TYPE="t3.micro"
AMI_PARAM="/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-6.1-x86_64"

aws() { command aws --profile "$PROFILE" --region "$REGION" "$@"; }

if ! aws iam get-role --role-name "$ROLE_NAME" >/dev/null 2>&1; then
  aws iam create-role --role-name "$ROLE_NAME" --assume-role-policy-document '{
    "Version":"2012-10-17",
    "Statement":[{"Effect":"Allow","Principal":{"Service":"ec2.amazonaws.com"},"Action":"sts:AssumeRole"}]
  }' >/dev/null
fi

if [[ "$(aws iam list-attached-role-policies --role-name "$ROLE_NAME" \
    --query "AttachedPolicies[?PolicyArn=='arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore'] | length(@)")" -eq 0 ]]; then
  aws iam attach-role-policy --role-name "$ROLE_NAME" --policy-arn arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore >/dev/null
fi

if ! aws iam get-instance-profile --instance-profile-name "$INSTANCE_PROFILE_NAME" >/dev/null 2>&1; then
  aws iam create-instance-profile --instance-profile-name "$INSTANCE_PROFILE_NAME" >/dev/null
fi

if [[ "$(aws iam get-instance-profile --instance-profile-name "$INSTANCE_PROFILE_NAME" \
    --query "InstanceProfile.Roles[?RoleName=='$ROLE_NAME'] | length(@)")" -eq 0 ]]; then
  aws iam add-role-to-instance-profile --instance-profile-name "$INSTANCE_PROFILE_NAME" --role-name "$ROLE_NAME" >/dev/null
fi

for i in {1..20}; do
  ok=$(aws iam get-instance-profile --instance-profile-name "$INSTANCE_PROFILE_NAME" \
      --query "length(InstanceProfile.Roles[?RoleName=='$ROLE_NAME'])" --output text) || ok=0
  [[ "$ok" -gt 0 ]] && break
  sleep 5
done

IP_ARN=$(aws iam get-instance-profile --instance-profile-name "$INSTANCE_PROFILE_NAME" --query 'InstanceProfile.Arn' --output text)

HELPER_SG_ID=$(aws ec2 describe-security-groups --filters "Name=group-name,Values=$HELPER_SG_NAME" "Name=vpc-id,Values=$VPC_ID" --query 'SecurityGroups[0].GroupId' --output text || true)
if [[ -z "$HELPER_SG_ID" || "$HELPER_SG_ID" == "None" ]]; then
  HELPER_SG_ID=$(aws ec2 create-security-group --group-name "$HELPER_SG_NAME" --description "SSM helper box for EFS" --vpc-id "$VPC_ID" --query 'GroupId' --output text)
  aws ec2 authorize-security-group-egress --group-id "$HELPER_SG_ID" --ip-permissions IpProtocol=-1,IpRanges='[{CidrIp=0.0.0.0/0}]' >/dev/null 2>&1 || true
fi

VPCE_SG_ID=$(aws ec2 describe-security-groups --filters "Name=group-name,Values=$VPCE_SG_NAME" "Name=vpc-id,Values=$VPC_ID" --query 'SecurityGroups[0].GroupId' --output text || true)
if [[ -z "$VPCE_SG_ID" || "$VPCE_SG_ID" == "None" ]]; then
  VPCE_SG_ID=$(aws ec2 create-security-group --group-name "$VPCE_SG_NAME" --description "SSM VPC interface endpoints" --vpc-id "$VPC_ID" --query 'GroupId' --output text)
fi

aws ec2 authorize-security-group-ingress --group-id "$VPCE_SG_ID" --protocol tcp --port 443 --source-group "$HELPER_SG_ID" >/dev/null 2>&1 || true

for SVC in ssm ec2messages ssmmessages; do
  SVC_NAME="com.amazonaws.$REGION.$SVC"
  EXISTS=$(aws ec2 describe-vpc-endpoints --filters "Name=vpc-id,Values=$VPC_ID" "Name:service-name,Values=$SVC_NAME" --query 'VpcEndpoints[0].VpcEndpointId' --output text || true)
  if [[ -z "$EXISTS" || "$EXISTS" == "None" ]]; then
    aws ec2 create-vpc-endpoint --vpc-id "$VPC_ID" --service-name "$SVC_NAME" --vpc-endpoint-type Interface --subnet-ids "${SUBNET_IDS[@]}" --security-group-ids "$VPCE_SG_ID" >/dev/null
  fi
done

AMI_ID=$(aws ssm get-parameter --name "$AMI_PARAM" --query 'Parameter.Value' --output text)

INSTANCE_ID=$(aws ec2 run-instances --image-id "$AMI_ID" --instance-type "$INSTANCE_TYPE" --iam-instance-profile Arn="$IP_ARN" --subnet-id "$SUBNET_ID" --security-group-ids "$HELPER_SG_ID" --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$INSTANCE_NAME_TAG}]" --query 'Instances[0].InstanceId' --output text)

aws ec2 wait instance-status-ok --instance-ids "$INSTANCE_ID"

for i in {1..24}; do
  PING=$(aws ssm describe-instance-information --filters "Key=InstanceIds,Values=$INSTANCE_ID" --query 'InstanceInformationList[0].PingStatus' --output text 2>/dev/null || true)
  [[ "$PING" == "Online" ]] && break
  sleep 5
done

if [[ "$PING" != "Online" ]]; then
  echo "Instance not Online in SSM. Check endpoints/SGs." >&2
  exit 1
fi

aws ssm start-session --target "$INSTANCE_ID"
