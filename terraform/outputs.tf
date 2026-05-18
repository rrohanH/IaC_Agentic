output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.web.id
}

output "public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.web.public_ip
}

output "public_dns" {
  description = "Public DNS name of the EC2 instance"
  value       = aws_instance.web.public_dns
}

output "ssh_private_key_pem" {
  description = "Private key for SSH access to the EC2 instance"
  value       = tls_private_key.ssh.private_key_pem
  sensitive   = true
}
