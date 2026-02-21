# EC2 Instance Configuration
# Creates EC2 instance with Docker installed via user data
# Enforces IMDSv2 for enhanced security

# Generate SSH key pair
resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Create AWS key pair using generated public key
resource "aws_key_pair" "ec2_key" {
  key_name   = var.key_name
  public_key = tls_private_key.ssh_key.public_key_openssh

  tags = {
    Name = "DevSecOps Key Pair"
  }
}

# Create EC2 instance in public subnet
resource "aws_instance" "web" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.web.id]
  iam_instance_profile   = aws_iam_instance_profile.ssm_profile.name
  key_name               = aws_key_pair.ec2_key.key_name

  # Enforce IMDSv2
  metadata_options {
    http_tokens = "required"
  }

  # User data to install Docker
  user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo yum install -y docker
              sudo service docker start
              sudo usermod -a -G docker ec2-user
              sudo usermod -a -G docker root
              EOF

  tags = {
    Name = "DevSecOps Web Server"
  }
}
