#--- terraform.tfvars ---

project_name = "tfec2lambdacw"

# networking
vpc_cidr = "10.0.0.0/16"
subpub_cidrs = [
  "10.0.0.0/24",
  #"10.0.2.0/24",
]
subprv_cidrs = [
  "10.0.1.0/24",
  #"10.0.3.0/24",
]
service_ports = [
  { # ssh
    from_port = 22,
    to_port   = 22
  },
  { # web http
    from_port = 80,
    to_port   = 80
  },
  { # web https
    from_port = 443,
    to_port   = 443
  },
  { # web https
    from_port = 5555,
    to_port   = 5555
  },
]
access_ip = "77.21.223.112/32" # "0.0.0.0/0"

#--- logs
log_group_trigger_name  = "log_group_to_trigger_mylambda"
log_stream_trigger_name = "stream_1"

#--- compute
key_name        = "tfec2lambdacw_key"
public_key_path = "~/.ssh/id_rsa.pub"
instance_type   = "t2.micro"
