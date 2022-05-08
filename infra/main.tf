# --- root/main.tf ---

module "log" {
  source              = "./log"
#   vpc_cidr            = local.vpc_cidr
#   access_ip           = var.access_ip
#   security_groups     = local.security_groups
#   sn_count            = 2
#   max_subnets         = 20
#   public_cidrs_front  = [for i in range(1, 255, 10) : cidrsubnet(local.vpc_cidr, 8, i)]
#   public_cidrs_back   = [for i in range(2, 255, 10) : cidrsubnet(local.vpc_cidr, 8, i)]
#   private_cidrs_front = [for i in range(3, 255, 10) : cidrsubnet(local.vpc_cidr, 8, i)]
#   private_cidrs_back  = [for i in range(4, 255, 10) : cidrsubnet(local.vpc_cidr, 8, i)]
#   private_cidrs_rds   = [for i in range(5, 255, 10) : cidrsubnet(local.vpc_cidr, 8, i)]
#   db_subnet_group     = true
}


module "networking" {
  source              = "./networking"
  vpc_cidr            = local.vpc_cidr
  access_ip           = var.access_ip
  security_groups     = local.security_groups
  sn_count            = 2
  max_subnets         = 20
  public_cidrs_front  = [for i in range(1, 255, 10) : cidrsubnet(local.vpc_cidr, 8, i)]
  public_cidrs_back   = [for i in range(2, 255, 10) : cidrsubnet(local.vpc_cidr, 8, i)]
  private_cidrs_front = [for i in range(3, 255, 10) : cidrsubnet(local.vpc_cidr, 8, i)]
  private_cidrs_back  = [for i in range(4, 255, 10) : cidrsubnet(local.vpc_cidr, 8, i)]
  private_cidrs_rds   = [for i in range(5, 255, 10) : cidrsubnet(local.vpc_cidr, 8, i)]
  db_subnet_group     = true
}

module "database" {
  source                 = "./database"
  db_storage             = 10
  db_engine_version      = "13.6"
  db_instance_class      = "db.t3.micro"
  dbname                 = var.dbname
  dbuser                 = var.dbuser
  dbpassword             = var.dbpassword
  db_identifier          = "tt-db"
  skip_db_snapshot       = true
  db_subnet_group_name   = module.networking.db_subnet_group_name
  vpc_security_group_ids = module.networking.db_security_group
}

# Create ALBs
module "loadbalancing" {
  for_each = local.lb

  source                 = "./loadbalancing"
  lb_name                = each.value.name
  public_sg              = module.networking.public_sg[each.key]
  public_subnets         = module.networking.public_subnets[each.key]
  tg_port                = each.value.port
  tg_protocol            = "HTTP"
  vpc_id                 = module.networking.vpc_id
  lb_healthy_threshold   = 2
  lb_unhealthy_threshold = 2
  lb_timeout             = 3
  lb_interval            = 30
  listener_port          = 80
  listener_protocol      = "HTTP"
}

module "compute" {
  source                = "./compute"
  instance_type         = "t2.micro"
  public_sg_front       = module.networking.public_sg_front
  private_sg_front      = module.networking.private_sg_front
  private_subnets_front = module.networking.private_subnets_front
  public_subnets_front  = module.networking.public_subnets_front

  public_sg_back       = module.networking.public_sg_back
  private_sg_back      = module.networking.private_sg_back
  private_subnets_back = module.networking.private_subnets_back

  instance_profile  = module.log.ec2_profile

  min_size = var.min_size
  max_size = var.max_size
  desired_capacity = var.desired_capacity
  key_name                  = "tt-key"
  private_key_path          = var.private_key_path
  public_key_path           = join(".", [var.private_key_path, "pub"])
  dbhost                    = split(":", module.database.dbendpoint)[0]
  dbport                    = split(":", module.database.dbendpoint)[1]
  gitlab_token              = var.gitlab_token
  dbuser                    = var.dbuser
  dbpass                    = var.dbpassword
  dbname                    = var.dbname
  lb_target_group_front_arn = module.loadbalancing["front"].lb_target_group_arn
  lb_target_group_back_arn  = module.loadbalancing["back"].lb_target_group_arn
  apiendpoint               = module.loadbalancing["back"].lb_endpoint[0]
  tg_port                   = 8000
  create_bastion            = var.create_bastion
}
