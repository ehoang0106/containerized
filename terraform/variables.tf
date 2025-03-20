variable "db_username" {
  description = "Username for db"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "Password for the db"
  type        = string
  sensitive   = true
} 