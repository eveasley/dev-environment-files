output "nat_gateway_ids" {
  description = "List of NAT Gateway IDs created"
  value       = aws_nat_gateway.this[*].id
}

output "nat_gateway_ips" {
  description = "List of Elastic IPs allocated to the NAT Gateways"
  value       = aws_eip.nat[*].public_ip
}
