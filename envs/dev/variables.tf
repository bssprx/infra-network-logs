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