#!/usr/bin/env zsh
set -euo pipefail

PROFILE="admin"
REGION="us-east-2"
VPC_ID="vpc-0969ce579f19b3ebf"
SUBNET_IDS=("subnet-0cba2d5cb47dd69a2" "subnet-0746bb5310ed0c16f")
SUBNET_ID="${SUBNET_IDS[1]}"
ROLE_NAME="EC2SSMRole-efs-helper"
INSTANCE_PROFILE_NAME="$ROLE_NAME"
SECURITY_GROUP_NAME="efs-helper-sg"
VPCE_SG_NAME="vpce-ssm-sg"

if ! aws iam get-role --role-name "$ROLE_NAME" --profile "$PROFILE" --region "$REGION" >/dev/null 2>&1; then
  aws iam create-role --role-name "$ROLE_NAME" --profile "$PROFILE" --region "$REGION" \
    --assume-role-policy-document '{
      "Version":"2012-10-17",
      "Statement":[{"Effect":"Allow","Principal":{"Service":"ec2.amazonaws.com"},"Action":"sts:AssumeRole"}]
    }'
fi

ATTACHED=$(aws iam list-attached-role-policies --role-name "$ROLE_NAME" --profile "$PROFILE" --region "$REGION" \
  --query "AttachedPolicies[?PolicyArn=='arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore'] | length(@)" --output text)
if [ "$ATTACHED" -eq 0 ]; then
  aws iam attach-role-policy --role-name "$ROLE_NAME" --profile "$PROFILE" --region "$REGION" \
    --policy-arn arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore
fi

if ! aws iam get-instance-profile --instance-profile-name "$INSTANCE_PROFILE_NAME" --profile "$PROFILE" --region "$REGION" >/dev/null 2>&1; then
  aws iam create-instance-profile --instance-profile-name "$INSTANCE_PROFILE_NAME" --profile "$PROFILE" --region "$REGION"
fi

HAS_ROLE=$(aws iam get-instance-profile --instance-profile-name "$INSTANCE_PROFILE_NAME" --profile "$PROFILE" --region "$REGION" \
  --query "InstanceProfile.Roles[?RoleName=='$ROLE_NAME'] | length(@)" --output text)
if [ "$HAS_ROLE" -eq 0 ]; then
  aws iam add-role-to-instance-profile --instance-profile-name "$INSTANCE_PROFILE_NAME" --role-name "$ROLE_NAME" --profile "$PROFILE" --region "$REGION"
fi

for i in {1..20}; do
  HAS_ROLE=$(aws iam get-instance-profile --instance-profile-name "$INSTANCE_PROFILE_NAME" --profile "$PROFILE" --region "$REGION" \
    --query "InstanceProfile.Roles[?RoleName=='$ROLE_NAME'] | length(@)" --output text)
  [ "$HAS_ROLE" -gt 0 ] && break
  sleep 5
done
sleep 10

IP_ARN=$(aws iam get-instance-profile --instance-profile-name "$INSTANCE_PROFILE_NAME" --profile "$PROFILE" --region "$REGION" --query 'InstanceProfile.Arn' --output text)

SG_ID=$(aws ec2 describe-security-groups --profile "$PROFILE" --region "$REGION" \
  --filters "Name=group-name,Values=$SECURITY_GROUP_NAME" "Name=vpc-id,Values=$VPC_ID" \
  --query 'SecurityGroups[0].GroupId' --output text)
if [[ -z "$SG_ID" || "$SG_ID" == "None" ]]; then
  SG_ID=$(aws ec2 create-security-group --profile "$PROFILE" --region "$REGION" \
    --group-name "$SECURITY_GROUP_NAME" --description "SSM helper box for EFS" --vpc-id "$VPC_ID" \
    --query 'GroupId' --output text)
  aws ec2 authorize-security-group-egress --profile "$PROFILE" --region "$REGION" \
    --group-id "$SG_ID" --ip-permissions IpProtocol=-1,IpRanges='[{CidrIp=0.0.0.0/0}]' || true
fi

VPCE_SG_ID=$(aws ec2 describe-security-groups --profile "$PROFILE" --region "$REGION" \
  --filters "Name=group-name,Values=$VPCE_SG_NAME" "Name=vpc-id,Values=$VPC_ID" \
  --query 'SecurityGroups[0].GroupId' --output text)
if [[ -z "$VPCE_SG_ID" || "$VPCE_SG_ID" == "None" ]]; then
  VPCE_SG_ID=$(aws ec2 create-security-group --profile "$PROFILE" --region "$REGION" \
    --group-name "$VPCE_SG_NAME" --description "SSM VPC endpoints" --vpc-id "$VPC_ID" \
    --query 'GroupId' --output text)
fi

aws ec2 authorize-security-group-ingress --profile "$PROFILE" --region "$REGION" \
  --group-id "$VPCE_SG_ID" --protocol tcp --port 443 --source-group "$SG_ID" 2>/dev/null || true

for SVC in ssm ec2messages ssmmessages; do
  aws ec2 create-vpc-endpoint --profile "$PROFILE" --region "$REGION" \
    --vpc-id "$VPC_ID" \
    --service-name "com.amazonaws.$REGION.$SVC" \
    --vpc-endpoint-type Interface \
    --subnet-ids "${SUBNET_IDS[@]}" \
    --security-group-ids "$VPCE_SG_ID" >/dev/null || true
done

AMI_PARAM="/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-6.1-x86_64"
AMI_ID=$(aws ssm get-parameter --profile "$PROFILE" --region "$REGION" --name "$AMI_PARAM" --query 'Parameter.Value' --output text)

INSTANCE_ID=$(aws ec2 run-instances --profile "$PROFILE" --region "$REGION" \
  --image-id "$AMI_ID" \
  --instance-type t3.micro \
  --iam-instance-profile Arn="$IP_ARN" \
  --subnet-id "$SUBNET_ID" \
  --security-group-ids "$SG_ID" \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=efs-helper}]' \
  --query 'Instances[0].InstanceId' --output text)

while true; do
  STATUS=$(aws ssm describe-instance-information --profile "$PROFILE" --region "$REGION" \
    --filters "Key=InstanceIds,Values=$INSTANCE_ID" \
    --query 'InstanceInformationList[0].PingStatus' --output text || echo "None")
  [[ "$STATUS" == "Online" ]] && break
  sleep 10
done

aws ssm start-session --profile "$PROFILE" --region "$REGION" --target "$INSTANCE_ID"
