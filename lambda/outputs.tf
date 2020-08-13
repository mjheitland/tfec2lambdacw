#--- lambda/outputs.tf ---
output "lambda" {
  value = aws_lambda_function.mylambda.handler
}
output "region" {
  value = local.region
}
