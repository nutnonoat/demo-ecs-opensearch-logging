#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REGION="${AWS_REGION:-ap-southeast-1}"
PROJECT=$(terraform -chdir="$SCRIPT_DIR" console -no-color <<< 'var.project' 2>/dev/null | tr -d '"')
cd "$SCRIPT_DIR"

echo "=== Step 1: Terraform init ==="
terraform init -input=false

echo "=== Step 2: Create ECR repository ==="
terraform apply -target=aws_ecr_repository.app -auto-approve

echo "=== Step 3: Build and push multi-arch Docker image ==="
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_REPO="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${PROJECT}-app"

aws ecr get-login-password --region "$REGION" | \
  docker login --username AWS --password-stdin "${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"

# Ensure multi-arch builder exists
if ! docker buildx inspect multiarch &>/dev/null; then
  docker buildx create --name multiarch --driver docker-container --use
else
  docker buildx use multiarch
fi

docker buildx build \
  --platform linux/amd64,linux/arm64 \
  --provenance=false \
  -t "${ECR_REPO}:latest" \
  --push \
  ./app

echo "=== Step 4: Update app_image and deploy all ==="
sed -i.bak "s|^app_image.*|app_image = \"${ECR_REPO}:latest\"|" terraform.tfvars
rm -f terraform.tfvars.bak

echo ""
echo "ECR image pushed: ${ECR_REPO}:latest (linux/amd64 + linux/arm64)"
echo ""
echo "Ready to deploy. Run:"
echo "  terraform apply"
echo ""
echo "Or to preview first:"
echo "  terraform plan"
