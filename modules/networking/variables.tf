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
variable "allowed_ssh_cidrs" {
  description = "List of CIDR blocks allowed to access SSH (port 22)"
  type        = list(string)
  default     = ["10.0.0.0/8"]
  validation {
    condition     = alltrue([for cidr in var.allowed_ssh_cidrs : can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}\\/(\\d|[12]\\d|3[0-2])$", cidr))])
    error_message = "Each entry in allowed_ssh_cidrs must be a valid IPv4 CIDR block."
  }
}

variable "allowed_grafana_cidrs" {
  description = "List of CIDR blocks allowed to access Grafana (port 3000)"
  type        = list(string)
  default     = []
  validation {
    condition     = alltrue([for cidr in var.allowed_grafana_cidrs : can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}\\/(\\d|[12]\\d|3[0-2])$", cidr))])
    error_message = "Each entry in allowed_grafana_cidrs must be a valid IPv4 CIDR block."
  }
}

variable "allowed_syslog_cidrs" {
  description = "List of CIDR blocks allowed to send Syslog (port 514 TCP/UDP)"
  type        = list(string)
  default     = []
  validation {
    condition     = alltrue([for cidr in var.allowed_syslog_cidrs : can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}\\/(\\d|[12]\\d|3[0-2])$", cidr))])
    error_message = "Each entry in allowed_syslog_cidrs must be a valid IPv4 CIDR block."
  }
}

# Logging Node and Monitoring Variables
variable "enable_cloudwatch_alarms" {
  description = "Flag to enable CloudWatch alarms and monitoring resources"
  type        = bool
  default     = false
}

variable "ssh_ingress_cidrs" {
  description = "CIDR blocks allowed to access SSH (port 22) on the logging node"
  type        = list(string)
  default     = []
  validation {
    condition     = alltrue([for cidr in var.ssh_ingress_cidrs : can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}\\/(\\d|[12]\\d|3[0-2])$", cidr))])
    error_message = "Each entry in ssh_ingress_cidrs must be a valid IPv4 CIDR block."
  }
}

variable "grafana_ingress_cidrs" {
  description = "CIDR blocks allowed to access Grafana (port 3000) on the logging node"
  type        = list(string)
  default     = []
  validation {
    condition     = alltrue([for cidr in var.grafana_ingress_cidrs : can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}\\/(\\d|[12]\\d|3[0-2])$", cidr))])
    error_message = "Each entry in grafana_ingress_cidrs must be a valid IPv4 CIDR block."
  }
}

variable "syslog_ingress_cidrs" {
  description = "CIDR blocks allowed to send Syslog traffic to the logging node (port 514 TCP/UDP)"
  type        = list(string)
  default     = []
  validation {
    condition     = alltrue([for cidr in var.syslog_ingress_cidrs : can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}\\/(\\d|[12]\\d|3[0-2])$", cidr))])
    error_message = "Each entry in syslog_ingress_cidrs must be a valid IPv4 CIDR block."
  }
}

variable "alarm_topic_arns" {
  description = "List of SNS topic ARNs to notify when CloudWatch alarms are triggered"
  type        = list(string)
  default     = []
}