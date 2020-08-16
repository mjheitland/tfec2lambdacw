# How to trigger a Lambda using CloudWatch events from an ec2 in a private subnet

## Components

This Terraform project shows how to specify and deploy the following components:
+ VPC
+ 1 internet gateway
+ 1 public subnet
+ 1 private subnet
+ 1 security group
+ 1 public route table (opening ingress ports listed in terraform.tfvars)
+ 1 private default route table for the local traffic
+ 1 private VPC endpoint for CloudWatch
+ 1 log group 
+ 1 log stream
+ 1 bastion host in public subnet (to remote into private host)
+ 1 private host in private subnet (to trigger lambda)
+ 1 lambda
+ 1 log group subscription (to trigger lambda)
+ various policies, roles, security groups

## Setup
Prerequisites:
* create a keypair with ssh-keygen in ~/.ssh (two files: ~/.ssh/id_rsa and ~/.ssh/id_rsa.pub)

Terraform setup commands:
* terraform init
* terraform apply -auto-approve

## Test
* macOS only: ssh-add
* ssh -A -i ~/.ssh/id_rsa ec2-user@&lt;public ip of bastion&gt;
* ssh ec2-user@&lt;private ip of private ec2 instance&gt;
* cd /var/myscripts
* source send_cw_event.sh # sends a CW event to log_group_to_trigger_mylambda
* check /aws/lambda/mylambda # lambda 'mylambda' was triggered by the new event in log_group_to_trigger_mylambda

## Teardown
* terraform destroy -auto-approve
* rm -rfv **/.terraform terraform.tfstate* # remove all recursive subdirectories
