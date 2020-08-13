#--- networking/outputs.tf ---
output "vpc_id" {
  value = aws_vpc.tfec2lambdacw_vpc.id
}
output "igw_id" {
  value = aws_internet_gateway.tfec2lambdacw_igw.id
}
output "subpub_ids" {
  value = aws_subnet.tfec2lambdacw_subpub.*.id
}
output "subprv_ids" {
  value = aws_subnet.tfec2lambdacw_subprv.*.id
}
output "sg_id" {
  value = aws_security_group.tfec2lambdacw_sg.id
}
output "rtpub_ids" {
  value = aws_route_table.tfec2lambdacw_rtpub.*.id
}
output "rtprv_ids" {
  value = aws_default_route_table.tfec2lambdacw_rtprv.*.id
}
