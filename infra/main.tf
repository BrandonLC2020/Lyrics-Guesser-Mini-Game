# --- Frontend: S3 & CloudFront ---
# Placeholders for S3 Bucket and CloudFront Distribution

resource "aws_s3_bucket" "frontend_bucket" {
  bucket = "${var.project_name}-frontend-assets"
}

# --- Backend: EC2 ---
# Placeholder for VPC, Subnet, and EC2 Instance

resource "aws_instance" "backend_server" {
  ami           = "ami-0c55b159cbfafe1f0" # Placeholder AMI (Amazon Linux 2023 in us-east-1)
  instance_type = var.backend_instance_type

  tags = {
    Name = "${var.project_name}-backend-ec2"
  }
}
