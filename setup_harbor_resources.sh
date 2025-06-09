#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -euo pipefail

# === Configuration ===
REGION="us-west-2"  # Oregon
VPC_CIDR="10.0.0.0/16"
SUBNET_CIDR="10.0.1.0/24"
AMI_ID="ami-088b41ffb0933423f"   # Amazon Linux 2023 (example)
INSTANCE_TYPE="t3.micro"
KEY_NAME="my-key"
BUCKET_NAME="harbor_s3"
POLICY_NAME="HarborS3AccessPolicy"
ROLE_NAME="HarborEC2Role"
PROFILE_NAME="HarborEC2Profile"
INSTANCE_NAME="Harbor_Server"

# Helper function to extract IDs from AWS CLI output
get_id() {
    jq -r "$1" | tr -d '\n' | sed 's/\r$//' 
}

# === Step 1: Create VPC ===
VPC_ID=$(aws ec2 create-vpc --cidr-block "$VPC_CIDR" --region "$REGION" \
    --tag-specifications "ResourceType=vpc,Tags=[{Key=Name,Value=HarborVPC}]" \
    --query 'Vpc.VpcId' --output text)
echo "Created VPC: $VPC_ID"

# === Step 2: Create Subnet ===
SUBNET_ID=$(aws ec2 create-subnet --vpc-id "$VPC_ID" --cidr-block "$SUBNET_CIDR" \
    --availability-zone "${REGION}a" \
    --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=HarborSubnet}]" \
    --query 'Subnet.SubnetId' --output text)
echo "Created Subnet: $SUBNET_ID"

# === Step 3: Create Security Group ===
SG_ID=$(aws ec2 create-security-group --group-name HarborSG \
    --description "Security Group for Harbor" --vpc-id "$VPC_ID" \
    --region "$REGION" --query 'GroupId' --output text)
echo "Created Security Group: $SG_ID"

# Allow HTTPS inbound from the VPC
aws ec2 authorize-security-group-ingress --group-id "$SG_ID" --protocol tcp \
    --port 443 --cidr "$VPC_CIDR" --region "$REGION"

# === Step 4: Launch EC2 Instance ===
INSTANCE_ID=$(aws ec2 run-instances --image-id "$AMI_ID" --instance-type "$INSTANCE_TYPE" \
    --subnet-id "$SUBNET_ID" --security-group-ids "$SG_ID" --key-name "$KEY_NAME" \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$INSTANCE_NAME}]" \
    --region "$REGION" --query 'Instances[0].InstanceId' --output text)
echo "Launched EC2 Instance: $INSTANCE_ID"

# === Step 5: Create S3 Bucket ===
aws s3api create-bucket --bucket "$BUCKET_NAME" --region "$REGION" \
    --create-bucket-configuration LocationConstraint="$REGION"

aws s3api put-public-access-block --bucket "$BUCKET_NAME" \
    --public-access-block-configuration BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true

echo "Created S3 bucket: $BUCKET_NAME"

# === Step 6: Create IAM Policy ===
cat > harbor-s3-policy.json <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::$BUCKET_NAME",
        "arn:aws:s3:::$BUCKET_NAME/*"
      ]
    }
  ]
}
POLICY

aws iam create-policy --policy-name "$POLICY_NAME" --policy-document file://harbor-s3-policy.json || true

# === Step 7: Create IAM Role ===
cat > trust-policy.json <<TRUST
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {"Service": "ec2.amazonaws.com"},
      "Action": "sts:AssumeRole"
    }
  ]
}
TRUST

aws iam create-role --role-name "$ROLE_NAME" --assume-role-policy-document file://trust-policy.json || true

aws iam attach-role-policy --role-name "$ROLE_NAME" \
    --policy-arn arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):policy/$POLICY_NAME

aws iam create-instance-profile --instance-profile-name "$PROFILE_NAME" || true
aws iam add-role-to-instance-profile --instance-profile-name "$PROFILE_NAME" --role-name "$ROLE_NAME" || true
sleep 10
aws ec2 associate-iam-instance-profile --instance-id "$INSTANCE_ID" --iam-instance-profile Name="$PROFILE_NAME" --region "$REGION"

echo "Setup complete. Instance $INSTANCE_ID has access to bucket $BUCKET_NAME"
