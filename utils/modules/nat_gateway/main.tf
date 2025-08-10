resource "aws_eip" "nat" {
  count = length(var.public_subnet_ids)

  vpc = true

  tags = merge(
    var.tags,
    { Name = "nat-eip-${count.index + 1}" }
  )
}

resource "aws_nat_gateway" "this" {
  count         = length(var.public_subnet_ids)
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = var.public_subnet_ids[count.index]

  tags = merge(
    var.tags,
    { Name = "nat-gateway-${count.index + 1}" }
  )
}