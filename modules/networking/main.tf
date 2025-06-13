terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

locals {
  private_subnet_azs = [for s in aws_subnet.private : s.availability_zone]
}

# VPC
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(
    var.tags,
    {
      Name        = "${var.name_prefix}-vpc"
      Environment = var.environment
      Project     = var.project
    }
  )
}

# Public Subnets
resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = merge(
    var.tags,
    {
      Name        = "${var.name_prefix}-public-${count.index}"
      Environment = var.environment
      Project     = var.project
    }
  )
}

# Private Subnets
resource "aws_subnet" "private" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = merge(
    var.tags,
    {
      Name        = "${var.name_prefix}-private-${count.index}"
      Environment = var.environment
      Project     = var.project
    }
  )
}

# NAT Gateway Module
module "nat_gateway" {
  source      = "../nat_gateway"
  for_each    = { for idx, subnet in aws_subnet.public : idx => subnet.id }
  name_prefix = "${var.name_prefix}-${each.key}"
  subnet_id   = each.value
  tags        = var.tags
}

# Route Tables and Routes
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  tags = merge(
    var.tags,
    {
      Name        = "${var.name_prefix}-public-rt"
      Environment = var.environment
      Project     = var.project
    }
  )
}

resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route" "public_internet_access" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(
    var.tags,
    {
      Name        = "${var.name_prefix}-igw"
      Environment = var.environment
      Project     = var.project
    }
  )
}

resource "aws_route_table" "private" {
  count  = length(aws_subnet.private)
  vpc_id = aws_vpc.this.id

  tags = merge(
    var.tags,
    {
      Name        = "${var.name_prefix}-private-rt-${count.index}"
      Environment = var.environment
      Project     = var.project
    }
  )
}

resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

resource "aws_route" "private_nat_gateway" {
  count                  = length(aws_route_table.private)
  route_table_id         = aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = values(module.nat_gateway)[count.index % length(module.nat_gateway)].nat_gateway_id
}

## Route Tables and Associations
# Private route tables for NAT routing
resource "aws_route_table" "private_nat" {
  count  = length(var.private_subnet_cidrs)
  vpc_id = aws_vpc.this.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = module.nat_gateway[count.index].nat_gateway_id
  }

  tags = merge(var.tags, {
    Name        = "${var.name_prefix}-private-nat-rt-${count.index}",
    Environment = var.environment,
    Project     = var.project
  })
}

## Transit Gateway Attachment
resource "aws_ec2_transit_gateway_vpc_attachment" "tgw_attachment" {
  count                     = var.transit_gateway_id != null ? 1 : 0
  subnet_ids                = [for s in aws_subnet.private : s.id if s.availability_zone == "us-east-1a" || s.availability_zone == "us-east-1c"]
  transit_gateway_id        = var.transit_gateway_id
  vpc_id                    = aws_vpc.this.id
  transit_gateway_default_route_table_association = true
  transit_gateway_default_route_table_propagation = true

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(var.tags, {
    Name              = "${var.name_prefix}-tgw-attachment",
    TGWAttachmentState = "unknown"  # Terraform doesn't expose state directly
  })
}





## Security Group for Logging
resource "aws_security_group" "logging_sg" {
  name        = "${var.name_prefix}-logging-sg"
  description = "Allow logging-related inbound traffic"
  vpc_id      = aws_vpc.this.id

  dynamic "ingress" {
    for_each = var.ssh_ingress_cidrs
    content {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = [ingress.value]
      description = "SSH"
    }
  }

  dynamic "ingress" {
    for_each = var.grafana_ingress_cidrs
    content {
      from_port   = 3000
      to_port     = 3000
      protocol    = "tcp"
      cidr_blocks = [ingress.value]
      description = "Grafana"
    }
  }

  dynamic "ingress" {
    for_each = var.syslog_ingress_cidrs
    content {
      from_port   = 514
      to_port     = 514
      protocol    = "tcp"
      cidr_blocks = [ingress.value]
      description = "Syslog TCP"
    }
  }

  dynamic "ingress" {
    for_each = var.syslog_ingress_cidrs
    content {
      from_port   = 514
      to_port     = 514
      protocol    = "udp"
      cidr_blocks = [ingress.value]
      description = "Syslog UDP"
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name        = "${var.name_prefix}-logging-sg",
    Environment = var.environment,
    Project     = var.project
  })
}


# CloudWatch Log Group for TGW attachment failures
resource "aws_cloudwatch_log_group" "tgw_attachment_failures" {
  count             = var.enable_cloudwatch_alarms ? 1 : 0
  name              = "/aws/events/tgw-attachment-failures"
  retention_in_days = 14

  tags = merge(var.tags, {
    Name        = "${var.name_prefix}-tgw-failures-log-group",
    Environment = var.environment,
    Project     = var.project
  })
}

# EventBridge rule for failed TGW attachment events
resource "aws_cloudwatch_event_rule" "tgw_attachment_failed" {
  count       = var.enable_cloudwatch_alarms ? 1 : 0
  name        = "${var.name_prefix}-tgw-attachment-failed"
  description = "Capture failed Transit Gateway attachment events"
  event_pattern = jsonencode({
    "source": ["aws.ec2"],
    "detail-type": ["AWS API Call via CloudTrail"],
    "detail": {
      "eventName": ["CreateTransitGatewayVpcAttachment"],
      "responseElements": {
        "transitGatewayVpcAttachment": {
          "state": ["failed"]
        }
      }
    }
  })

  tags = merge(var.tags, {
    Name        = "${var.name_prefix}-tgw-attachment-failed-rule",
    Environment = var.environment,
    Project     = var.project
  })
}

resource "aws_cloudwatch_event_target" "tgw_attachment_failed_to_logs" {
  count     = var.enable_cloudwatch_alarms ? 1 : 0
  rule      = aws_cloudwatch_event_rule.tgw_attachment_failed[0].name
  target_id = "SendToLogGroup"
  arn       = aws_cloudwatch_log_group.tgw_attachment_failures[0].arn
}

resource "aws_cloudwatch_metric_alarm" "tgw_attachment_failures_alarm" {
  count               = var.enable_cloudwatch_alarms ? 1 : 0
  alarm_name          = "${var.name_prefix}-TGWAttachmentFailures"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "FailedInvocations"
  namespace           = "AWS/Events"
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "Alarm when Transit Gateway VPC Attachment fails"
  alarm_actions       = var.alarm_topic_arns
  dimensions = {
    RuleName = aws_cloudwatch_event_rule.tgw_attachment_failed[0].name
  }

  tags = merge(var.tags, {
    Name        = "${var.name_prefix}-tgw-failure-alarm",
    Environment = var.environment,
    Project     = var.project
  })
}