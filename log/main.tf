#--- log/main.tf

resource "aws_cloudwatch_log_group" "log_group_to_trigger_mylambda" {
  name = var.log_group_trigger_name

  tags = {
    Name         = format("%s_%s", var.project_name, var.log_group_trigger_name)
    project_name = var.project_name
  }
}

resource "aws_cloudwatch_log_stream" "log_stream_to_trigger_mylambda" {
  name           = var.log_stream_trigger_name
  log_group_name = aws_cloudwatch_log_group.log_group_to_trigger_mylambda.name
}
