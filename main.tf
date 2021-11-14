#--- root/main.tf ---
provider "aws" {
  region = var.region
}

module "networking" {
  source = "./networking"

  access_ip     = var.access_ip
  project_name  = var.project_name
  service_ports = var.service_ports
  subpub_cidrs  = var.subpub_cidrs
  subprv_cidrs  = var.subprv_cidrs
  vpc_cidr      = var.vpc_cidr
}

module "log" {
  source = "./log"

  log_group_trigger_name  = var.log_group_trigger_name
  log_stream_trigger_name = var.log_stream_trigger_name
  project_name            = var.project_name
}

module "compute" {
  source = "./compute"

  instance_type           = var.instance_type
  key_name                = var.key_name
  log_group_trigger_name  = var.log_group_trigger_name
  log_stream_trigger_name = var.log_stream_trigger_name
  project_name            = var.project_name
  public_key_path         = var.public_key_path
  sg_id                   = module.networking.sg_id
  subprv_ids              = module.networking.subprv_ids
  subpub_ids              = module.networking.subpub_ids
}

module "lambda" {
  source = "./lambda"

  log_group_trigger_arn  = module.log.log_group_trigger_arn
  log_group_trigger_name = var.log_group_trigger_name
  project_name           = var.project_name
  subprv_ids             = module.networking.subprv_ids
  vpc_cidr               = var.vpc_cidr
  vpc_id                 = module.networking.vpc_id
}
