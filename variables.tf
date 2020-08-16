#--- root/variables.tf

variable "project_name" {
  description = "project name is used as resource tag"
  type        = string
}

variable region {
  description = "AWS region we are deploying to"
  type        = string
  default     = "eu-west-1"
}

#--- networking
variable "vpc_cidr" {
  description = "separate vpc for this project"
  type        = string
}
variable "subpub_cidrs" { 
  description = "cidr blocks for public subnets"
  type        = list(string)
}
variable "subprv_cidrs" { 
  description = "cidr blocks for private subnets"
  type        = list(string)
}
variable "service_ports" {
  description = "ports that we open on our ec2 instance"
  type = list(object({
    from_port = number
    to_port   = number
  }))
}
variable "access_ip" {
  description = "cidr block for incoming traffic"
  type        = string
}

#--- compute
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
variable "log_group_trigger_name" {
  description = "name of log group that triggers the lambda"
  type        = string
}
variable "log_stream_trigger_name" {
  description = "name of log stream that triggers the lambda"
  type        = string
}
