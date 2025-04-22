#!/bin/bash

set -e

# === CONFIGURACIÓN PERSONALIZADA ===

REGION="us-east-1"
ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
OUTPOST_ID="OUTPUT_ID"  # Reemplaza si es necesario
BUCKET_NAME="harbor-storage-outpost"
POLICY_NAME="HarborS3OutpostsAccessPolicy"
ROLE_NAME="HarborEC2OutpostsRole"
INSTANCE_PROFILE="HarborEC2OutpostsProfile"
INSTANCE_ID="i-xxxxxxxxxxxxxxxxx"  # <-- REEMPLAZA con el ID de tu instancia EC2

echo "Usando cuenta: $ACCOUNT_ID"
echo "Región: $REGION"
echo "Outpost ID: $OUTPOST_ID"

# === Paso 1: Crear el bucket S3 en el Outpost ===

echo "Creando bucket en Outposts (puede requerir endpoint de control)..."
aws s3outposts create-bucket \
  --outpost-id "$OUTPOST_ID" \
  --bucket-name "$BUCKET_NAME"

# === Paso 2: Crear policy IAM con acceso a S3 Outposts ===

echo "📜 Creando IAM Policy para Outposts..."
aws iam create-policy \
  --policy-name "$POLICY_NAME" \
  --policy-document file://harbor-s3-outposts-policy.json || echo "Puede que ya exista."

# === Paso 3: Crear IAM Role para EC2 ===

echo "Creando IAM Role para EC2..."
aws iam create-role \
  --role-name "$ROLE_NAME" \
  --assume-role-policy-document file://trust-policy.json || echo "Role ya podría existir."

# === Paso 4: Asociar policy al role ===

echo "🔗 Asociando policy al role..."
aws iam attach-role-policy \
  --role-name "$ROLE_NAME" \
  --policy-arn arn:aws:iam::$ACCOUNT_ID:policy/$POLICY_NAME

# === Paso 5: Crear el Instance Profile ===

echo "Creando Instance Profile..."
aws iam create-instance-profile \
  --instance-profile-name "$INSTANCE_PROFILE" || echo "Puede que ya exista."

aws iam add-role-to-instance-profile \
  --instance-profile-name "$INSTANCE_PROFILE" \
  --role-name "$ROLE_NAME" || echo "Role ya podría estar asociado."

sleep 10

# === Paso 6: Asociar Profile a la instancia EC2 ===

echo "Asociando IAM Instance Profile a la EC2..."
aws ec2 associate-iam-instance-profile \
  --instance-id "$INSTANCE_ID" \
  --iam-instance-profile Name="$INSTANCE_PROFILE"

echo "Listo. EC2 puede acceder al bucket de Outposts '$BUCKET_NAME'"