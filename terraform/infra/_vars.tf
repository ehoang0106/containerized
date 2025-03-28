variable "region" {
  type        = string
  default     = "us-west-1"
}

variable "db_username" {
  type        = string
  sensitive = true
}

variable "db_password" {
  type        = string
  sensitive = true
}

variable "cert_arn" {
  default = "arn:aws:acm:us-west-1:706572850235:certificate/eac6e688-8e0c-4545-a122-d67d1d7bf04a"
}
