# --- root/locals.tf ---

locals {
  vpc_cidr = "10.124.0.0/16"
}

locals {
  lb = {
    front = {
      name = "tt-loadbalancer-front"
      port = 8080
    }
    back = {
      name = "tt-loadbalancer-back"
      port = 8081
    }
  }
}

locals {
  security_groups = {
    public_front = {
      #    public = {
      name        = "public_sg_front"
      description = "public access to frontend"
      ingress = {
        ssh = {
          from        = 22
          to          = 22
          protocol    = "tcp"
          cidr_blocks = [var.access_ip]
        }
        open = {
          from        = 0
          to          = 0
          protocol    = -1
          cidr_blocks = [var.access_ip]
        }
        http = {
          from        = 80
          to          = 80
          protocol    = "tcp"
          cidr_blocks = ["0.0.0.0/0"]
        }
        app = {
          from        = 8080
          to          = 8080
          protocol    = "tcp"
          cidr_blocks = ["0.0.0.0/0"]
        }
      }

    }

    private_front = {
      name        = "private_sg_front"
      description = "private access to frontend"
      ingress = {
        ssh = {
          from        = 22
          to          = 22
          protocol    = "tcp"
          cidr_blocks = [var.access_ip]
        }
        open = {
          from        = 0
          to          = 0
          protocol    = -1
          cidr_blocks = [var.access_ip]
        }
        http = {
          from        = 80
          to          = 80
          protocol    = "tcp"
          cidr_blocks = ["0.0.0.0/0"]
        }
        app = {
          from        = 8080
          to          = 8080
          protocol    = "tcp"
          cidr_blocks = ["0.0.0.0/0"]
        }
      }
    }







    public_back = {
      name        = "public_sg_back"
      description = "public access to backend"
      ingress = {
        ssh = {
          from        = 22
          to          = 22
          protocol    = "tcp"
          cidr_blocks = [var.access_ip]
        }
        open = {
          from        = 0
          to          = 0
          protocol    = -1
          cidr_blocks = [var.access_ip]
        }
        http = {
          from        = 80
          to          = 80
          protocol    = "tcp"
          cidr_blocks = ["0.0.0.0/0"]
        }
        app = {
          from        = 8081
          to          = 8081
          protocol    = "tcp"
          cidr_blocks = ["0.0.0.0/0"]
        }
      }

    }

    private_back = {
      name        = "private_sg_back"
      description = "private access to backend"
      ingress = {
        ssh = {
          from        = 22
          to          = 22
          protocol    = "tcp"
          cidr_blocks = [var.access_ip]
        }
        open = {
          from        = 0
          to          = 0
          protocol    = -1
          cidr_blocks = [var.access_ip]
        }
        http = {
          from        = 80
          to          = 80
          protocol    = "tcp"
          cidr_blocks = ["0.0.0.0/0"]
        }
        app = {
          from        = 8081
          to          = 8081
          protocol    = "tcp"
          cidr_blocks = ["0.0.0.0/0"]
        }
      }
    }


    rds = {
      name        = "rds_sg"
      description = "rds access"
      ingress = {
        pgsql = {
          from        = 5432
          to          = 5432
          protocol    = "tcp"
          cidr_blocks = [local.vpc_cidr]
        }
      }
    }
  }
}

