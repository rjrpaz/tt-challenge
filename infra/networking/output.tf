# --- networking/output.tf ---
output "vpc_id" {
  value = aws_vpc.tt_vpc.id
}

output "db_subnet_group_name" {
  value = aws_db_subnet_group.tt_rds_subnetgroup.*.name
}

output "db_security_group" {
  value = aws_security_group.tt_sg["rds"].id
}

output "public_sg_front" {
  value = aws_security_group.tt_sg["public_front"].id
}

output "private_sg_front" {
  value = aws_security_group.tt_sg["private_front"].id
}

output "public_subnets_front" {
  value = aws_subnet.tt_public_subnet_front.*.id
}

output "private_subnets_front" {
  value = aws_subnet.tt_private_subnet_front.*.id
}

output "public_sg_back" {
  value = aws_security_group.tt_sg["public_back"].id
}

output "private_sg_back" {
  value = aws_security_group.tt_sg["private_back"].id
}

output "private_subnets_back" {
  value = aws_subnet.tt_private_subnet_back.*.id
}

output "public_sg" {
  value = {
    front = aws_security_group.tt_sg["public_front"].id
    back  = aws_security_group.tt_sg["public_back"].id
  }
}

output "public_subnets" {
  value = {
    front = aws_subnet.tt_public_subnet_front.*.id
    back  = aws_subnet.tt_public_subnet_back.*.id
  }
}
