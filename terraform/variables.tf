variable "region" {
  type        = string
  default     = "us-west-1"
}

variable "db_username" {
  type        = string
  sensitive   = true
}

variable "db_password" {
  type        = string
  sensitive   = true
} 