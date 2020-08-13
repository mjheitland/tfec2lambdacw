#--- log/variables.tf
variable "project_name" {
  description = "project name is used as resource tag"
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
