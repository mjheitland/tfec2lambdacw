#--- compute/variables.tf
variable "project_name" {
  description = "project name is used as resource tag"
  type        = string
}
variable "key_name" {
  description = "name of keypair to access ec2 instances"
  type        = string
}
variable "public_key_path" {
  description = "file path on deployment machine to public rsa key to access ec2 instances"
  type        = string
}
variable "instance_type" {
  description = "type of ec2 instance"
  type        = string
}
variable "subpub_ids" {
  description = "ids of public subnets"
  type        = list(string)
}
variable "subprv_ids" {
  description = "ids of private subnets"
  type        = list(string)
}
variable "sg_id" {
  description = "id of security group"
  type        = string
}
variable "log_group_trigger_name" {
  description = "name of log group that triggers the lambda"
  type        = string
}
variable "log_stream_trigger_name" {
  description = "name of log stream that triggers the lambda"
  type        = string
}
