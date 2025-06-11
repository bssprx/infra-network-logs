variable "aws_region" {
  default = "us-east-1"
}

variable "instance_type" {
  default = "t4g.medium"
}

variable "ssh_key_name" {
  description = "Name of your existing AWS EC2 Key Pair"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, prod)"
  default        = "dev"
}

variable "project" {
  description = "Project name"
  default        = "logging-stack"
}