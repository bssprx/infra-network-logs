locals {
  private_subnet_azs = [for s in aws_subnet.private : s.availability_zone]
}
## VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-vpc"
  })
}

## Subnets
resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = element(var.availability_zones, count.index)
  map_public_ip_on_launch = true

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-public-${count.index}"
  })
}

resource "aws_subnet" "private" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = element(var.availability_zones, count.index)

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-private-${count.index}"
  })
}

## Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-igw"
  })
}

## Route Tables and Associations
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-public-rt"
  })
}

resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  count  = length(var.private_subnet_cidrs) > 0 && var.transit_gateway_id != null ? 1 : 0
  vpc_id = aws_vpc.main.id

  tags = merge(var.tags, {
    Name        = "${var.name_prefix}-private-rt",
    Environment = var.environment,
    Project     = var.project
  })
}

resource "aws_route_table_association" "private" {
  count          = length(var.private_subnet_cidrs)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[0].id
}

resource "aws_route" "transit_gateway_routes" {
  count = var.transit_gateway_id != null && var.create_tgw_routes ? length(var.transit_gateway_routes) : 0

  route_table_id         = aws_route_table.private[0].id
  destination_cidr_block = var.transit_gateway_routes[count.index]
  transit_gateway_id     = var.transit_gateway_id
}

## Transit Gateway Attachment
resource "aws_ec2_transit_gateway_vpc_attachment" "tgw_attachment" {
  count                     = var.transit_gateway_id != null ? 1 : 0
  subnet_ids                = [for s in aws_subnet.private : s.id if s.availability_zone == "us-east-1a" || s.availability_zone == "us-east-1c"]
  transit_gateway_id        = var.transit_gateway_id
  vpc_id                    = aws_vpc.main.id
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false

  # timeouts block is not supported for this resource in Terraform
  # timeouts {
  #   create = "20m"
  # }

  depends_on = [
    aws_route_table_association.private
  ]

  tags = merge(var.tags, {
    Name              = "${var.name_prefix}-tgw-attachment",
    TGWAttachmentState = "unknown"  # Terraform doesn't expose state directly
  })
}

resource "aws_ec2_transit_gateway_route_table_association" "tgw_route_table_assoc" {
  count                         = var.transit_gateway_id != null && var.transit_gateway_route_table_id != null ? 1 : 0
  transit_gateway_attachment_id = aws_ec2_transit_gateway_vpc_attachment.tgw_attachment[0].id
  transit_gateway_route_table_id = var.transit_gateway_route_table_id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "tgw_route_table_prop" {
  count                         = var.transit_gateway_id != null && var.transit_gateway_route_table_id != null ? 1 : 0
  transit_gateway_attachment_id = aws_ec2_transit_gateway_vpc_attachment.tgw_attachment[0].id
  transit_gateway_route_table_id = var.transit_gateway_route_table_id
}



## Security Group for Logging
resource "aws_security_group" "logging_sg" {
  name        = "${var.name_prefix}-logging-sg"
  description = "Allow logging-related inbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 514
    to_port     = 514
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Syslog UDP"
  }

  ingress {
    from_port   = 514
    to_port     = 514
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Syslog TCP"
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH"
  }

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Grafana"
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