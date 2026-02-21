#!/bin/bash

# Terraform Deployment Script
# Initializes, plans, applies Terraform configuration and saves outputs

set -e  # Exit on error

# Default to dev environment if not specified
ENVIRONMENT=${1:-dev}

echo "=========================================="
echo "Starting Terraform Deployment - ${ENVIRONMENT} environment"
echo "=========================================="

# Initialize Terraform
echo "Initializing Terraform..."
terraform init

# Format Terraform files
echo "Formatting Terraform files..."
terraform fmt

# Validate configuration
echo "Validating Terraform configuration..."
terraform validate

# Plan changes
echo "Planning Terraform changes..."
terraform plan -var-file="${ENVIRONMENT}.tfvars" -out=tfplan

# Apply changes
echo "Applying Terraform configuration..."
terraform apply tfplan

# Remove plan file
rm -f tfplan

echo "=========================================="
echo "Saving Outputs"
echo "=========================================="

# Save all outputs to JSON file
echo "Saving all outputs to outputs.json..."
terraform output -json > outputs.json

# Save all outputs to text file
echo "Saving all outputs to outputs.txt..."
terraform output > outputs.txt

# Save private key to PEM file
echo "Saving private key to ${ENVIRONMENT}-devsecops-key.pem..."
terraform output -raw private_key_pem > ${ENVIRONMENT}-devsecops-key.pem
chmod 400 ${ENVIRONMENT}-devsecops-key.pem

# Save instance public IP
echo "Saving instance public IP to instance_ip.txt..."
terraform output -raw instance_public_ip > instance_ip.txt

echo "=========================================="
echo "Deployment Complete!"
echo "=========================================="
echo "Environment: ${ENVIRONMENT}"
echo "Instance Public IP: $(cat instance_ip.txt)"
echo "SSH Command: ssh -i ${ENVIRONMENT}-devsecops-key.pem ec2-user@$(cat instance_ip.txt)"
echo ""
echo "Files created:"
echo "  - outputs.json (all outputs in JSON format)"
echo "  - outputs.txt (all outputs in text format)"
echo "  - ${ENVIRONMENT}-devsecops-key.pem (private SSH key)"
echo "  - instance_ip.txt (instance public IP)"
echo "=========================================="
