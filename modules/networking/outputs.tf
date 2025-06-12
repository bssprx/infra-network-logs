# -------------------------------
# VPC and Subnet Outputs
# -------------------------------

output "vpc_id" {
  description = "The ID of the VPC."
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "List of public subnet IDs."
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "List of private subnet IDs."
  value       = aws_subnet.private[*].id
}

# -------------------------------
# Route Table and Security Group Outputs
# -------------------------------

output "public_route_table_id" {
  description = "The ID of the public route table."
  value       = aws_route_table.public.id
}

output "logging_sg_id" {
  description = "The ID of the logging security group."
  value       = aws_security_group.logging_sg.id
}

# -------------------------------
# Transit Gateway Attachment Output
# -------------------------------
output "tgw_attachment_state" {
  description = "The state of the Transit Gateway VPC attachment."
  value       = try(one(aws_ec2_transit_gateway_vpc_attachment.tgw_attachment[*].state), null)
}


output "tgw_attachment_id" {
  description = "The ID of the Transit Gateway VPC attachment."
  value       = one(aws_ec2_transit_gateway_vpc_attachment.tgw_attachment[*].id)
}

# output "tgw_attachment_failure_metric_alarm_arn" {
#   description = "ARN of the CloudWatch metric alarm that monitors failed TGW VPC attachments."
#   value       = aws_cloudwatch_metric_alarm.tgw_attachment_failure_alarm.arn
# }


# -------------------------------
# NAT Gateway and Elastic IP Outputs
# -------------------------------

output "nat_gateway_ids" {
  description = "List of NAT Gateway IDs."
  value       = aws_nat_gateway.this[*].id
}

output "nat_eip_ids" {
  description = "List of Elastic IP IDs associated with the NAT Gateways."
  value       = aws_eip.nat[*].id
}