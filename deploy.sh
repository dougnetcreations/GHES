#!/bin/bash
set -e

echo "🚀 Deploying GHES VM Autoscaling Runners..."

# 1. Build Packer image
echo "📦 Building optimized runner image..."
cd packer/
export ARM_CLIENT_ID=$ARM_CLIENT_ID
export ARM_CLIENT_SECRET=$ARM_CLIENT_SECRET  
export ARM_SUBSCRIPTION_ID=$ARM_SUBSCRIPTION_ID
export ARM_TENANT_ID=$ARM_TENANT_ID
packer build -var-file=../terraform/terraform.tfvars ubuntu-runner.pkr.hcl
IMAGE_ID=$(packer buildvars | grep managed_image_id | cut -d'=' -f2 | tr -d "'")
cd ..

# 2. Deploy Terraform
echo "☁️  Deploying autoscaling infrastructure..."
cd terraform/
terraform init
terraform plan -var="packer_image_id=$IMAGE_ID" -var-file=terraform.tfvars
read -p "Apply? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  terraform apply -auto-approve -var="packer_image_id=$IMAGE_ID" -var-file=terraform.tfvars
  echo "✅ Deployment complete!"
  echo "VMSS: $(terraform output vmss_id)"
  echo "Scale Set Name: $(terraform output vmss_name)"
fi
