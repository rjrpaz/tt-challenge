# --- root/variables.tf ---

variable "aws_region" {
  default = "us-east-1"
}

variable "create_bastion" {
  type = bool
}

variable "min_size" {
  default = 2
  # default = 1
}

variable "max_size" {
  default = 4
}

variable "desired_capacity" {
  default = 2
  # default = 1
}

variable "access_ip" {
  type = string
}

variable "dbname" {
  type = string
}

variable "dbuser" {
  type      = string
  sensitive = true
}

variable "dbpassword" {
  type      = string
  sensitive = true
}

variable "private_key_path" {
  type = string
}

variable "gitlab_token" {
  type      = string
  sensitive = true
}

variable "cdn_domain_name" {
  default = "cdn.tt.com"
}
