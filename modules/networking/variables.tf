# VPC & Subnet Configuration
variable "vpc_cidr_block" {
  description = "The CIDR block for the VPC"
  type        = string
}

variable "public_subnet_cidrs" {
  description = "List of CIDR blocks for public subnets"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "List of CIDR blocks for private subnets"
  type        = list(string)
}

# Availability Zones Configuration
variable "availability_zones" {
  description = "Default availability zones to use within this module"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1c"]
}

# Transit Gateway Configuration
variable "transit_gateway_id" {
  description = "The ID or ARN of the company's shared transit gateway"
  type        = string
  default     = null
}

# Tagging and Naming
variable "name_prefix" {
  description = "Prefix to use for naming resources"
  type        = string
}

variable "tags" {
  description = "Common tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "environment" {
  description = "Deployment environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "project" {
  description = "Project name for tagging purposes"
  type        = string
}

variable "enable_nat_gateway" {
  description = "Whether to create NAT Gateways for private subnet internet access"
  type        = bool
  default     = true
}

variable "nat_eip_tags" {
  description = "Tags to apply to NAT Gateway Elastic IPs"
  type        = map(string)
  default     = {}
}