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

  validation {
    condition = !(var.create_tgw_routes) || (length(var.availability_zones) == 2 && alltrue([
      contains(var.availability_zones, "us-east-1a"),
      contains(var.availability_zones, "us-east-1c")
    ]))
    error_message = "When create_tgw_routes is true, availability_zones must contain exactly 'us-east-1a' and 'us-east-1c'."
  }
}

# Transit Gateway Configuration
variable "transit_gateway_id" {
  description = "The ID or ARN of the company's shared transit gateway"
  type        = string
  default     = null
}

variable "transit_gateway_routes" {
  description = "List of CIDR blocks that should be routed to the transit gateway"
  type        = list(string)
  default     = []
}

variable "create_tgw_routes" {
  description = "Whether to create transit gateway routes"
  type        = bool
  default     = false
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

variable "enable_cloudwatch_alarms" {
  description = "Flag to enable creation of CloudWatch alarms for TGW attachment failures"
  type        = bool
  default     = false
}

# CloudWatch Alarm Thresholds Configuration
variable "cloudwatch_alarm_thresholds" {
  description = "Configuration map for CloudWatch alarm thresholds"
  type = object({
    evaluation_periods = number
    period             = number
    datapoints_to_alarm = number
  })
  default = {
    evaluation_periods   = 3
    period               = 60
    datapoints_to_alarm  = 2
  }
}

variable "alarm_topic_arns" {
  description = "List of SNS topic ARNs to notify on TGW attachment failures"
  type        = list(string)
  default     = []
}