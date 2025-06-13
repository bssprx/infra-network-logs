variable "subnet_id" {
  description = "The ID of the public subnet in which to place the NAT Gateway"
  type        = string
}

variable "tags" {
  description = "Tags to apply to the NAT Gateway and associated resources"
  type        = map(string)
  default     = {}
}

variable "name_prefix" {
  description = "Prefix to use for naming the NAT Gateway"
  type        = string
}

resource "aws_eip" "nat" {
  domain = "vpc"
  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-nat-eip"
    }
  )
}

resource "aws_nat_gateway" "this" {
  allocation_id = aws_eip.nat.id
  subnet_id     = var.subnet_id

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-nat-gateway"
    }
  )
}

output "nat_gateway_id" {
  description = "The ID of the NAT Gateway"
  value       = aws_nat_gateway.this.id
}
