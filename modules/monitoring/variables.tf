variable "alb_arn_suffix" {
  description = "ALB ARN suffix for CloudWatch"
  type        = string
}

variable "tg_arn_suffix" {
  description = "Target group ARN suffix for CloudWatch"
  type        = string
}

variable "autoscaling_group_name" {
  description = "Auto Scaling Group name"
  type        = string
}

variable "alarm_email" {
  description = "Email address for alarm notifications"
  type        = string
}