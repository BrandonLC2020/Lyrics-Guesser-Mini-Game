variable "aws_region" {
  description = "The AWS region to deploy resources to."
  type        = "string"
  default     = "us-east-1"
}

variable "project_name" {
  description = "The name of the project, used for naming and tagging resources."
  type        = "string"
  default     = "lyrics-guesser-mini-game"
}

variable "backend_instance_type" {
  description = "The EC2 instance type for the backend application."
  type        = "string"
  default     = "t3.micro"
}
