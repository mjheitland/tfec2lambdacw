#--- compute/outputs.tf
output "keypair_id" {
  value = join(", ", aws_key_pair.keypair.*.id)
}
output "bastion_ids" {
  value = join(", ", aws_instance.bastion.*.id)
}
output "bastion_public_ips" {
  value = join(", ", aws_instance.bastion.*.public_ip)
}
