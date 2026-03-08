output "frontend_s3_bucket_name" {
  description = "The name of the S3 bucket for the frontend."
  value       = aws_s3_bucket.frontend_bucket.id
}

output "backend_ec2_public_ip" {
  description = "The public IP address of the backend EC2 instance."
  value       = aws_instance.backend_server.public_ip
}
