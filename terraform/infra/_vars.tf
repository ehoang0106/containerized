variable "region" {
  type        = string
  default     = "us-west-1"
}

variable "db_username" {
  type        = string
  default = "root"
}

variable "db_password" {
  type        = string
  default = "Xzkiller1698!"
}

variable "cert_arn" {
  default = "arn:aws:acm:us-west-1:706572850235:certificate/eac6e688-8e0c-4545-a122-d67d1d7bf04a"
}
