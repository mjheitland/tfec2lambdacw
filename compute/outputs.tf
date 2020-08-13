#--- compute/outputs.tf
output "keypair_id" {
  value = "${join(", ", aws_key_pair.tfec2lambdacw_keypair.*.id)}"
}
output "bastion_ids" {
  value = "${join(", ", aws_instance.tfec2lambdacw_bastion.*.id)}"
}
output "bastion_public_ips" {
  value = "${join(", ", aws_instance.tfec2lambdacw_bastion.*.public_ip)}"
}
