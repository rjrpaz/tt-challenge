# --- root/variables.tf ---

variable "aws_region" {
  default = "us-east-1"
}

variable "create_bastion" {
  type = bool
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
  type = string
}

#variable "lb" {
#    type = map(any)
#    description = "groups of lb params"
#}
