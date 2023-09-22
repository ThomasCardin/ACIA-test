# Variables
variable "postgres_db" {
  description = "Postgres db."
  default     = "postgres_database"
}

variable "postgres_user" {
  description = "Postgres user."
  default     = "postgres_user"
}

variable "postgres_password" {
  description = "Postgres password."
  default     = "postgres_password"
}

variable "postgres_host" {
  description = "Postgres host"
  default     = "postgres_host"
}

variable "user_ialab_password" {
  description = "ialab user password"
  default     = "ialab_user_password"
}
