#--- compute/main.tf
resource "aws_key_pair" "keypair" {
  key_name   = var.key_name
  public_key = file(var.public_key_path)
}

data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*"]
  }
  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "template_file" "userdata_bastion" {
  template = file("${path.module}/userdata_webserver.tpl")
  vars = {
    host_name               = "bastion"
    message                 = "example bastion msg 1"
    log_group_trigger_name  = var.log_group_trigger_name
    log_stream_trigger_name = var.log_stream_trigger_name
  }
}

data "template_file" "userdata_private" {
  template = file("${path.module}/userdata_private.tpl")
  vars = {
    host_name               = "private"
    message                 = "example private msg 1"
    log_group_trigger_name  = var.log_group_trigger_name
    log_stream_trigger_name = var.log_stream_trigger_name
  }
}

resource "aws_instance" "bastion" {
  count = length(var.subpub_ids)

  instance_type          = var.instance_type
  iam_instance_profile   = aws_iam_instance_profile.bastion_profile.name
  ami                    = data.aws_ami.amazon_linux_2.id
  key_name               = aws_key_pair.keypair.id
  subnet_id              = element(var.subpub_ids, count.index)
  vpc_security_group_ids = [var.sg_ping_id, var.sg_id]
  user_data              = data.template_file.userdata_bastion.*.rendered[0]
  tags = {
    Name         = format("%s_bastion_%d", var.project_name, count.index)
    project_name = var.project_name
  }
}


resource "aws_instance" "private" {
  count = length(var.subprv_ids)

  instance_type          = var.instance_type
  iam_instance_profile   = aws_iam_instance_profile.private_profile.name
  ami                    = data.aws_ami.amazon_linux_2.id
  key_name               = aws_key_pair.keypair.id
  subnet_id              = element(var.subprv_ids, count.index)
  vpc_security_group_ids = [var.sg_id]
  user_data              = data.template_file.userdata_private.*.rendered[0]
  tags = {
    Name         = format("%s_private_%d", var.project_name, count.index)
    project_name = var.project_name
  }
}

resource "aws_iam_role" "EC2-Cloudwatch-Role" {
  name               = "EC2-Cloudwatch-Role"
  path               = "/"
  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy" "EC2-SQS-Policy" {
  name   = "EC2-SQS-Policy"
  role   = aws_iam_role.EC2-Cloudwatch-Role.id
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "ApiSQSPolicy",
      "Action": [
        "sqs:*",
        "sqs:ReceiveMessage"
      ],
      "Resource": "*",
      "Effect": "Allow"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy" "EC2-Lambda-Policy" {
  name   = "EC2-Lambda-Policy"
  role   = aws_iam_role.EC2-Cloudwatch-Role.id
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "ApiSQSPolicy",
      "Action": [
        "lambda:*",
        "lambda:GetFunction",
        "lambda:CreateEventSourceMapping",
        "lambda:DeleteEventSourceMapping",
        "lambda:UpdateEventSourceMapping",
        "lambda:GetEventSourceMapping",
        "lambda:ListEventSourceMappings"
      ],
      "Resource": "*",
      "Effect": "Allow"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy" "EC2-Cloudwatch-Policy" {
  name   = "EC2-Cloudwatch-Policy"
  role   = aws_iam_role.EC2-Cloudwatch-Role.id
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "ApiLoggingPolicy",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams",
        "logs:PutLogEvents"
      ],
      "Resource": "*",
      "Effect": "Allow"
    }
  ]
}
POLICY
}

resource "aws_iam_instance_profile" "bastion_profile" {
  name = "bastion_profile"
  role = aws_iam_role.EC2-Cloudwatch-Role.name
}

resource "aws_iam_instance_profile" "private_profile" {
  name = "private_profile"
  role = aws_iam_role.EC2-Cloudwatch-Role.name
}
