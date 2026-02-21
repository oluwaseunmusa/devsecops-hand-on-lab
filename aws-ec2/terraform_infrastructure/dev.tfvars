# Development Environment Variables
# Use with: terraform apply -var-file="dev.tfvars"

aws_region         = "us-east-1"
vpc_cidr           = "10.0.0.0/16"
public_subnet_cidr = "10.0.1.0/20"
availability_zone  = "us-east-1a"
instance_type      = "t2.micro"
ami_id             = "ami-0c1fe732b5494dc14" # Amazon Linux 2023 - us-east-1
key_name           = "dev-devsecops-key"
