#!/bin/bash

set -e

### === CONFIGURACIÓN INICIAL ===

# Personaliza estos valores
BUCKET_NAME="harbor-storage"
REGION="us-east-1"
POLICY_NAME="HarborS3AccessPolicy"
ROLE_NAME="HarborEC2Role"
INSTANCE_PROFILE="HarborEC2Profile"
INSTANCE_ID="i-xxxxxxxxxxxxxxxxx"  # <-- REEMPLAZA con tu ID real de EC2
ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)

echo "Usando Account ID: $ACCOUNT_ID"
echo "Comenzando configuración para Harbor con S3 e IAM Role..."

### === Paso 1: Crear bucket S3 ===

echo "Creando bucket S3..."
aws s3api create-bucket \
  --bucket "$BUCKET_NAME" \
  --region "$REGION" \
  --create-bucket-configuration LocationConstraint="$REGION" || echo " Bucket puede que ya exista."

aws s3api put-public-access-block \
  --bucket "$BUCKET_NAME" \
  --public-access-block-configuration BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true

### === Paso 2: Crear policy IAM para S3 ===

cat > harbor-s3-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject",
        "s3:ListBucket",
        "s3:DeleteObject"
      ],
      "Resource": [
        "arn:aws:s3:::$BUCKET_NAME",
        "arn:aws:s3:::$BUCKET_NAME/*"
      ]
    }
  ]
}
EOF

echo "Creando IAM Policy..."
aws iam create-policy \
  --policy-name "$POLICY_NAME" \
  --policy-document file://harbor-s3-policy.json || echo " Policy puede que ya exista."

### === Paso 3: Crear IAM Role con trust para EC2 ===

cat > trust-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

echo "Creando IAM Role..."
aws iam create-role \
  --role-name "$ROLE_NAME" \
  --assume-role-policy-document file://trust-policy.json || echo "Role puede que ya exista."

### === Paso 4: Asociar policy al role ===

echo "Asociando policy al role..."
aws iam attach-role-policy \
  --role-name "$ROLE_NAME" \
  --policy-arn arn:aws:iam::$ACCOUNT_ID:policy/$POLICY_NAME

### === Paso 5: Crear Instance Profile y asociar al role ===

echo "Creando Instance Profile..."
aws iam create-instance-profile \
  --instance-profile-name "$INSTANCE_PROFILE" || echo "Instance Profile puede que ya exista."

aws iam add-role-to-instance-profile \
  --instance-profile-name "$INSTANCE_PROFILE" \
  --role-name "$ROLE_NAME" || echo "Role puede que ya esté asociado."

sleep 10

### === Paso 6: Asociar Profile a la instancia EC2 ===

echo "Asociando el Instance Profile a la EC2..."
aws ec2 associate-iam-instance-profile \
  --instance-id "$INSTANCE_ID" \
  --iam-instance-profile Name="$INSTANCE_PROFILE"

echo "¡Todo listo! La EC2 ahora puede usar el bucket $BUCKET_NAME vía IAM Role."