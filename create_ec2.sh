#!/usr/bin/env bash
set -euo pipefail

############################################
# CONFIG
############################################
PROFILE="default"                
REGION="us-east-2"
VPC_ID="vpc-xxxxxxxx"
SUBNET_ID="subnet-xxxxxxxx"      
ROUTE_TABLE_IDS=("rtb-xxxxxxxx")

INSTANCE_TYPE="t3.micro"
SG_NAME="efs-helper-sg"
ROLE_NAME="EC2SSMRole-efs-helper"
INSTANCE_PROFILE_NAME="$ROLE_NAME"
AMI_PARAM="/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-6.1-x86_64"  # AL2023 (SSM preinstalled)
EFS_FS_ID="fs-xxxxxxxx"
EFS_AP_ID="fsap-xxxxxxxx"
MOUNT_DIR="/mnt/efs"

############################################
# VPC EP if NO NAT
############################################
# If your subnet has no Internet/NAT, uncomment these to allow SSM to reach the instance.
# aws ec2 create-vpc-endpoint --profile "$PROFILE" --region "$REGION" \
#   --vpc-id "$VPC_ID" --service-name "com.amazonaws.$REGION.ssm" --vpc-endpoint-type Interface \
#   --subnet-ids "$SUBNET_ID" --security-group-ids "$SG_ID" >/dev/null
# aws ec2 create-vpc-endpoint --profile "$PROFILE" --region "$REGION" \
#   --vpc-id "$VPC_ID" --service-name "com.amazonaws.$REGION.ec2messages" --vpc-endpoint-type Interface \
#   --subnet-ids "$SUBNET_ID" --security-group-ids "$SG_ID" >/dev/null
# aws ec2 create-vpc-endpoint --profile "$PROFILE" --region "$REGION" \
#   --vpc-id "$VPC_ID" --service-name "com.amazonaws.$REGION.ssmmessages" --vpc-endpoint-type Interface \
#   --subnet-ids "$SUBNET_ID" --security-group-ids "$SG_ID" >/dev/null
# (Optional) S3 gateway endpoint for package repos if you’re fully private:
# aws ec2 create-vpc-endpoint --profile "$PROFILE" --region "$REGION" \
#   --vpc-id "$VPC_ID" --service-name "com.amazonaws.$REGION.s3" --vpc-endpoint-type Gateway \
#   --route-table-ids "${ROUTE_TABLE_IDS[@]}"

############################################
# IAM ROLE + SSM
############################################
aws iam create-role --profile "$PROFILE" --role-name "$ROLE_NAME" --assume-role-policy-document '{
  "Version":"2012-10-17",
  "Statement":[{"Effect":"Allow","Principal":{"Service":"ec2.amazonaws.com"},"Action":"sts:AssumeRole"}]
}' >/dev/null || true

aws iam attach-role-policy --profile "$PROFILE" --role-name "$ROLE_NAME" \
  --policy-arn arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore >/dev/null || true

aws iam create-instance-profile --profile "$PROFILE" --instance-profile-name "$INSTANCE_PROFILE_NAME" >/dev/null || true
aws iam add-role-to-instance-profile --profile "$PROFILE" --instance-profile-name "$INSTANCE_PROFILE_NAME" --role-name "$ROLE_NAME" >/dev/null || true

############################################
# EGRESS
############################################
SG_ID=$(aws ec2 create-security-group --profile "$PROFILE" --region "$REGION" \
  --group-name "$SG_NAME" --description "SSM helper box for EFS" --vpc-id "$VPC_ID" \
  --query 'GroupId' --output text 2>/dev/null || true)

if [[ "$SG_ID" == "None" || -z "$SG_ID" ]]; then
  SG_ID=$(aws ec2 describe-security-groups --profile "$PROFILE" --region "$REGION" \
    --filters "Name=group-name,Values=$SG_NAME" "Name=vpc-id,Values=$VPC_ID" \
    --query 'SecurityGroups[0].GroupId' --output text)
fi

# allow all egress SSM || add endpoints)
aws ec2 authorize-security-group-egress --profile "$PROFILE" --region "$REGION" \
  --group-id "$SG_ID" --ip-permissions IpProtocol=-1,IpRanges='[{CidrIp=0.0.0.0/0}]' 2>/dev/null || true

############################################
# SSM
############################################
AMI_ID=$(aws ssm get-parameter --profile "$PROFILE" --region "$REGION" \
  --name "$AMI_PARAM" --query 'Parameter.Value' --output text)

############################################
# LAUNCH
############################################
INSTANCE_ID=$(aws ec2 run-instances --profile "$PROFILE" --region "$REGION" \
  --image-id "$AMI_ID" --instance-type "$INSTANCE_TYPE" \
  --iam-instance-profile Name="$INSTANCE_PROFILE_NAME" \
  --subnet-id "$SUBNET_ID" \
  --security-group-ids "$SG_ID" \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=efs-helper}]' \
  --query 'Instances[0].InstanceId' --output text)

echo "Launched instance: $INSTANCE_ID"
aws ec2 wait instance-status-ok --profile "$PROFILE" --region "$REGION" --instance-ids "$INSTANCE_ID"

# Wait for SSM agent to register
echo "Waiting for SSM to report Online..."
until [[ "$(aws ssm describe-instance-information --profile "$PROFILE" --region "$REGION" \
  --filters "Key=InstanceIds,Values=$INSTANCE_ID" \
  --query 'InstanceInformationList[0].PingStatus' --output text 2>/dev/null)" == "Online" ]]; do
  sleep 5
done
echo "Instance is Online in SSM."

############################################
# EFS UTILS + MOUNT
############################################
aws ssm send-command --profile "$PROFILE" --region "$REGION" \
  --document-name "AWS-RunShellScript" \
  --comment "Install EFS utils and mount EFS" \
  --targets "Key=instanceids,Values=$INSTANCE_ID" \
  --parameters commands="$(cat <<'CMDS'
set -eux
# AL2023 uses dnf; AL2 uses yum — try both
sudo dnf -y install amazon-efs-utils || sudo yum -y install amazon-efs-utils
sudo mkdir -p '"$MOUNT_DIR"'
# Mount with TLS and Access Point
sudo mount -t efs -o tls,accesspoint='"$EFS_AP_ID"' '"$EFS_FS_ID"':/ '"$MOUNT_DIR"'
# Ensure POSIX owner/group expected by AP root (uid/gid 1000)
sudo chown 1000:1000 '"$MOUNT_DIR"'
# Sanity test
echo "hello from $(hostname)" | sudo tee '"$MOUNT_DIR"'/__efs_test.txt
ls -al '"$MOUNT_DIR"'
CMDS
)" >/dev/null

echo "Sent SSM command to mount EFS. Start a session if you want an interactive shell:"
echo "aws ssm start-session --profile $PROFILE --region $REGION --target $INSTANCE_ID"
