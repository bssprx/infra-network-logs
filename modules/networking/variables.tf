

variable "vpc_cidr_block" {
  description = "CIDR block for the VPC"
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

variable "availability_zones" {
  description = "List of availability zones to use"
  type        = list(string)
}

variable "name_prefix" {
  description = "Prefix for naming resources"
  type        = string
}

variable "environment" {
  description = "Deployment environment (e.g., dev, prod)"
  type        = string
}

variable "project" {
  description = "Project name for tagging"
  type        = string
}

variable "tags" {
  description = "Map of tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "transit_gateway_id" {
  description = "Transit Gateway ID to attach to"
  type        = string
}
variable "ssh_ingress_cidrs" {
  description = "List of CIDR blocks allowed to SSH"
  type        = list(string)
  default     = []
}

variable "grafana_ingress_cidrs" {
  description = "List of CIDR blocks allowed to access Grafana"
  type        = list(string)
  default     = []
}

variable "syslog_ingress_cidrs" {
  description = "List of CIDR blocks allowed to send syslog traffic"
  type        = list(string)
  default     = []
}

variable "enable_cloudwatch_alarms" {
  description = "Flag to enable or disable CloudWatch alarms"
  type        = bool
  default     = false
}

variable "alarm_topic_arns" {
  description = "List of SNS topic ARNs to notify when CloudWatch alarms are triggered"
  type        = list(string)
  default     = []
}