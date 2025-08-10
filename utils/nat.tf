module "nat_gateway" {
  source            = "./modules/nat_gateway"
  vpc_id            = var.vpc_id
  public_subnet_ids = var.public_subnet_ids

  environment = var.environment
  tags = merge(
    var.tags,
    {
      Name = "nat-gateway-${var.environment}"
    }
  )
}

resource "aws_route" "private_nat_route" {
  for_each = toset(var.private_route_table_ids)

  route_table_id         = each.key
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = module.nat_gateway.nat_gateway_ids[0]
}

