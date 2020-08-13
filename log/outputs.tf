#--- log/outputs.tf

output "log_group_trigger_arn" {
  value = aws_cloudwatch_log_group.log_group_to_trigger_mylambda.arn
}