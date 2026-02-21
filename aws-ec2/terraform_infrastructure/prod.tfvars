# Production Environment Variables
# Use with: terraform apply -var-file="prod.tfvars"

aws_region         = "us-west-2"
vpc_cidr           = "10.1.0.0/16"
public_subnet_cidr = "10.1.1.0/24"
availability_zone  = "us-west-2a"
instance_type      = "t2.small"
ami_id             = "ami-0c2ab3b8efb09f272" # Amazon Linux 2023 - us-west-2
key_name           = "prod-devsecops-key"
