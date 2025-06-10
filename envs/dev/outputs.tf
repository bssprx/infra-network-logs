output "logging_instance_ip" {
  value = aws_instance.logging_node.public_ip
}