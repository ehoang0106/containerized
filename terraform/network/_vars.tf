variable "region" {
  type        = string
  default     = "us-west-1"
}

variable "zone_id" {
  default = "Z09372142GLGU75DMF3RP"
}

# data "aws_lb" "orbwatch_alb" {
#   name = "orbwatch-alb"
# }