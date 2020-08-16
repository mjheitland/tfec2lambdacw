#--- networking/outputs.tf ---
output "vpc_id" {
  value = aws_vpc.vpc.id
}
output "igw_id" {
  value = aws_internet_gateway.igw.id
}
output "subpub_ids" {
  value = aws_subnet.subpub.*.id
}
output "subprv_ids" {
  value = aws_subnet.subprv.*.id
}
output "sg_id" {
  value = aws_security_group.sg_pub.id
}
output "rtpub_ids" {
  value = aws_route_table.rt_pub.*.id
}
output "rtprv_ids" {
  value = aws_route_table.rt_prv.*.id
}
output "natgw_eip" {
  value = aws_eip.natgw_eip.id
}
output "natgw" {
  value = aws_nat_gateway.natgw.id
}
