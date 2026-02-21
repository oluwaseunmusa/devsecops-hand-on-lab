# Outputs Configuration
# Exports important resource IDs and values for reference

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "public_subnet_id" {
  description = "Public subnet ID"
  value       = aws_subnet.public.id
}

output "security_group_id" {
  description = "Security group ID"
  value       = aws_security_group.web.id
}

output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.web.id
}

output "instance_public_ip" {
  description = "EC2 instance public IP"
  value       = aws_instance.web.public_ip
}

output "private_key_pem" {
  description = "Private key for SSH access (sensitive)"
  value       = tls_private_key.ssh_key.private_key_pem
  sensitive   = true
}

output "ssh_command" {
  description = "SSH command to connect to instance"
  value       = "ssh -i ${var.key_name}.pem ec2-user@${aws_instance.web.public_ip}"
}
