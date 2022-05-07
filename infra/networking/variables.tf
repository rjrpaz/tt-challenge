# --- networking/variables.tf ---
variable "vpc_cidr" {
  type = string
}

variable "public_cidrs_front" {
  type = list(any)
}

variable "private_cidrs_front" {
  type = list(any)
}

variable "public_cidrs_back" {
  type = list(any)
}

variable "private_cidrs_back" {
  type = list(any)
}

variable "private_cidrs_rds" {
  type = list(any)
}

variable "sn_count" {
  type = number
}

variable "max_subnets" {
  type = number
}

variable "access_ip" {
  type = string
}

variable "security_groups" {}

variable "db_subnet_group" {
  type = bool
}
