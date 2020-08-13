#--- lambda/main.tf

#---------------
# Data Providers
#---------------

data "aws_region" "current" { }

data "aws_caller_identity" "current" {}

data "archive_file" "mylambda" {
  type        = "zip"
  source_file = "./lambda/mylambda.py"
  output_path = "mylambda.zip"
}


#-------------------
# Locals
#-------------------
locals {
  region  = data.aws_region.current.name
  account = data.aws_caller_identity.current.account_id
}

#-------------------
# Roles and Policies
#-------------------

resource "aws_iam_role" "mylambda" {
    name               = format("%s_mylambda", var.project_name)

    tags = { 
      Name = format("%s_mylambda", var.project_name)
      project_name = var.project_name
    }

    assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy" "lambda_logging" {
    name   = "lambda_logging"
    role   = aws_iam_role.mylambda.id
    policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "logs:CreateLogGroup",
            "Resource": "arn:aws:logs:${local.region}:${local.account}:*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": [
                "arn:aws:logs:${local.region}:${local.account}:log-group:/aws/lambda/mylambda:*"
            ]
        }
    ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaENIManagementAccess"
  role       = aws_iam_role.mylambda.id
}


#---------------
# Security Group
#---------------

resource "aws_security_group" "sg_mylambda" {
  name        = "tfec2lambdacw_sg_mylambda"
  description = "Used to access lambda"
  vpc_id      = var.vpc_id
 ingress {
    description = "TLS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { 
    Name = format("%s_sgpub", var.project_name)
    project_name = var.project_name
  }
}


#----------------
# Lambda Function
#----------------

resource "aws_lambda_function" "mylambda" {
  filename          = "mylambda.zip"
  function_name     = "mylambda"
  role              = aws_iam_role.mylambda.arn
  handler           = "mylambda.mylambda"
  runtime           = "python3.7"
  description       = "A function to log to CloudWatch."
  source_code_hash  = data.archive_file.mylambda.output_base64sha256

  environment {
    variables = {
      "MyAccountId" = local.account
    }
  }

  vpc_config {
    subnet_ids         = var.subprv_ids
    security_group_ids = aws_security_group.sg_mylambda.*.id
  }

  tags = { 
    Name = format("%s_mylambda", var.project_name)
    project_name = var.project_name
  }
}

resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id  = "allow_cloudwatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.mylambda.arn
  principal     = "logs.${local.region}.amazonaws.com"
  source_arn    = "${var.log_group_trigger_arn}:*"
}

resource "aws_cloudwatch_log_subscription_filter" "mylambda_logfilter" {
  name            = "mylambda_logfilter"
  log_group_name  = var.log_group_trigger_name
  filter_pattern  = ""
  destination_arn = aws_lambda_function.mylambda.arn
  depends_on      = [aws_lambda_permission.allow_cloudwatch]
}