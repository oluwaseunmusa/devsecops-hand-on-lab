# DevSecOps Mentorship - AWS EC2 with Terraform

**Hands-On Lab**: Deploy a complete AWS infrastructure with VPC, EC2, and Docker using Terraform

This lab teaches infrastructure as code (IaC) fundamentals by provisioning a production-ready AWS environment with security best practices.

---

## 🎯 Learning Objectives

- Understand Terraform project structure and modular configuration
- Deploy AWS VPC with public subnet and internet gateway
- Launch EC2 instances with automated Docker installation
- Implement IAM roles for AWS Systems Manager (SSM) access
- Enforce IMDSv2 for enhanced EC2 metadata security
- Manage multi-environment deployments (dev/prod)
- Automate infrastructure deployment with GitHub Actions

---

## 🏗️ Infrastructure Components

### Networking
- **VPC**: Custom VPC with DNS support
- **Public Subnet**: Auto-assigns public IPs to instances
- **Internet Gateway**: Enables outbound internet access
- **Route Table**: Routes traffic to internet gateway
- **Security Group**: Allows HTTP (80), HTTPS (443), SSH (22), and custom ports (0-10000)

### Compute
- **EC2 Instance**: Amazon Linux 2023 with Docker pre-installed
- **SSH Key Pair**: Auto-generated RSA 4096-bit key for secure access
- **IAM Instance Profile**: Enables AWS SSM for secure remote management

### Security Features
- IMDSv2 enforcement (prevents SSRF attacks)
- IAM role-based access (no hardcoded credentials)
- Automated SSH key generation
- Environment-specific configurations

---

## 📁 Project Structure

```
terraform_infrastructure/
├── main.tf           # AWS provider configuration
├── variables.tf      # Input variable definitions
├── vpc.tf            # VPC, subnet, IGW, route table, security group
├── ec2.tf            # EC2 instance, key pair, user data
├── iam.tf            # IAM role and instance profile for SSM
├── outputs.tf        # Output values (IPs, IDs, SSH commands)
├── dev.tfvars        # Development environment variables
├── prod.tfvars       # Production environment variables
└── deploy.sh         # Automated deployment script

.github/workflows/
└── terraform.yml     # CI/CD pipeline for automated deployment
```

---

## 🚀 Quick Start

### Prerequisites

- [Terraform](https://www.terraform.io/downloads) v1.0+
- AWS account with appropriate permissions
- AWS CLI configured with credentials

### Option 1: Automated Deployment (Recommended)

```bash
cd terraform_infrastructure
chmod +x deploy.sh
./deploy.sh dev
```

This script will:
1. Initialize Terraform
2. Format and validate configuration
3. Plan and apply changes
4. Save outputs to files:
   - `outputs.json` - All outputs in JSON format
   - `outputs.txt` - Human-readable outputs
   - `dev-devsecops-key.pem` - Private SSH key (chmod 400)
   - `instance_ip.txt` - EC2 public IP address

### Option 2: Manual Deployment

```bash
cd terraform_infrastructure

# Initialize Terraform
terraform init

# Plan deployment (dev environment)
terraform plan -var-file="dev.tfvars"

# Apply configuration
terraform apply -var-file="dev.tfvars"

# Save private key for SSH access
terraform output -raw private_key_pem > dev-devsecops-key.pem
chmod 400 dev-devsecops-key.pem

# Get instance IP
terraform output instance_public_ip
```

### Connect to Your Instance

```bash
# Using the saved key file
ssh -i dev-devsecops-key.pem ec2-user@<INSTANCE_PUBLIC_IP>

# Or use the SSH command from outputs
terraform output ssh_command
```

---

## 🌍 Multi-Environment Deployment

### Development Environment (us-east-1)
```bash
./deploy.sh dev
```
- Instance type: `t2.micro`
- VPC CIDR: `10.0.0.0/16`
- Region: `us-east-1`

### Production Environment (us-west-2)
```bash
./deploy.sh prod
```
- Instance type: `t2.small`
- VPC CIDR: `10.1.0.0/16`
- Region: `us-west-2`

---

## 🔄 GitHub Actions CI/CD

Automate infrastructure deployment on every push to the main branch.

### Setup Instructions

#### 1. Create AWS OIDC Identity Provider

```bash
# In AWS IAM Console
Identity Providers → Add Provider
  Provider Type: OpenID Connect
  Provider URL: https://token.actions.githubusercontent.com
  Audience: sts.amazonaws.com
```

#### 2. Create IAM Role for GitHub Actions

```bash
# In AWS IAM Console
Roles → Create Role → Web Identity
  Identity Provider: token.actions.githubusercontent.com
  Audience: sts.amazonaws.com
  
# Attach Policies:
  - AmazonEC2FullAccess
  - AmazonVPCFullAccess
  - IAMFullAccess (for creating instance profiles)
```

#### 3. Configure Trust Policy

Edit the role's trust policy to restrict access to your repository:

```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": {
      "Federated": "arn:aws:iam::<AWS_ACCOUNT_ID>:oidc-provider/token.actions.githubusercontent.com"
    },
    "Action": "sts:AssumeRoleWithWebIdentity",
    "Condition": {
      "StringEquals": {
        "token.actions.githubusercontent.com:aud": "sts.amazonaws.com",
        "token.actions.githubusercontent.com:sub": "repo:<GITHUB_USERNAME>/<REPO_NAME>:ref:refs/heads/main"
      }
    }
  }]
}
```

#### 4. Add GitHub Secret

```bash
# In GitHub Repository
Settings → Secrets and Variables → Actions → New Repository Secret
  Name: AWS_ROLE_ARN
  Value: arn:aws:iam::<AWS_ACCOUNT_ID>:role/<ROLE_NAME>
```

#### 5. Trigger Deployment

Push to main branch or create a pull request. The workflow will:
- ✅ Initialize Terraform
- ✅ Check formatting
- ✅ Validate configuration
- ✅ Generate plan
- ✅ Apply changes (on push to main only)

---

## 📊 Outputs Reference

| Output | Description |
|--------|-------------|
| `vpc_id` | VPC identifier |
| `public_subnet_id` | Public subnet identifier |
| `security_group_id` | Security group identifier |
| `instance_id` | EC2 instance identifier |
| `instance_public_ip` | Public IP address for SSH/HTTP access |
| `private_key_pem` | Private SSH key (sensitive) |
| `ssh_command` | Ready-to-use SSH connection command |

---

## 🔧 Customization Guide

### Change Instance Type

Edit `dev.tfvars` or `prod.tfvars`:
```hcl
instance_type = "t3.medium"
```

### Update AMI for Different Region

Find the latest Amazon Linux 2023 AMI:
```bash
aws ec2 describe-images \
  --owners amazon \
  --filters "Name=name,Values=al2023-ami-*" \
  --query 'Images | sort_by(@, &CreationDate) | [-1].ImageId' \
  --region us-west-2
```

### Restrict SSH Access to Your IP

Edit `vpc.tf` security group:
```hcl
ingress {
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = ["YOUR_IP/32"]  # Replace with your IP
}
```

### Add Additional User Data

Edit `ec2.tf` user_data section:
```bash
user_data = <<-EOF
            #!/bin/bash
            sudo yum update -y
            sudo yum install -y docker git
            sudo service docker start
            sudo usermod -a -G docker ec2-user
            EOF
```

---

## 🧹 Cleanup

**Important**: Always destroy resources to avoid AWS charges.

```bash
cd terraform_infrastructure

# Destroy dev environment
terraform destroy -var-file="dev.tfvars"

# Destroy prod environment
terraform destroy -var-file="prod.tfvars"
```

---

## 🐛 Troubleshooting

### Issue: AMI not found in region
**Solution**: Update `ami_id` in your `.tfvars` file with the correct AMI for your target region.

### Issue: Permission denied when connecting via SSH
**Solution**: Ensure key file has correct permissions:
```bash
chmod 400 dev-devsecops-key.pem
```

### Issue: GitHub Actions fails with authentication error
**Solution**: 
- Verify `AWS_ROLE_ARN` secret is correctly set
- Check IAM role trust policy matches your repository
- Ensure role has required permissions

### Issue: EC2 instance not accessible
**Solution**:
- Verify security group allows traffic on required ports
- Check instance has public IP assigned
- Confirm route table has route to internet gateway

### Issue: Terraform state lock error
**Solution**: This lab uses local state. Ensure no other Terraform processes are running in the same directory.

---

## 📚 Key Concepts Covered

- **Infrastructure as Code (IaC)**: Declarative infrastructure management
- **Terraform Modules**: Organized, reusable configuration files
- **Variable Management**: Environment-specific configurations with `.tfvars`
- **Output Values**: Extracting and using resource attributes
- **User Data**: Automated instance configuration on launch
- **IAM Roles**: Secure, temporary credentials for AWS services
- **IMDSv2**: Enhanced metadata service security
- **CI/CD**: Automated infrastructure deployment with GitHub Actions
- **OIDC Authentication**: Keyless authentication for GitHub Actions

---

## 🎓 Next Steps

1. Explore AWS Systems Manager Session Manager for SSH-less access
2. Implement remote state with S3 and DynamoDB for state locking
3. Add monitoring with CloudWatch alarms
4. Deploy a containerized application using the pre-installed Docker
5. Implement auto-scaling with launch templates and ASG
6. Add a load balancer for high availability

---

## 📝 License

This is a training lab for the DevSecOps Mentorship program.
